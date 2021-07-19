/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import AwsCommonRuntimeKit
#if os(Linux)
     import Glibc
 #else
     import Darwin
 #endif

public class CRTClientEngine: HttpClientEngine {
    
    private var logger: LogAgent
    private var crtLogger: Logger
    private var connectionPools: [Endpoint: HttpClientConnectionManager] = [:]
    private let CONTENT_LENGTH_HEADER = "Content-Length"
    private let AWS_COMMON_RUNTIME = "AwsCommonRuntime"
    private let DEFAULT_STREAM_WINDOW_SIZE = 16 * 1024 * 1024 // 16 MB
    
    public let bootstrap: ClientBootstrap
    public let eventLoopGroup: EventLoopGroup
    private let socketOptions: SocketOptions
    private let tlsContextOptions: TlsContextOptions
    private let tlsContext: TlsContext
    private let windowSize: Int
    private let maxConnectionsPerEndpoint: Int
    
    init(eventLoopGroup: EventLoopGroup, config: CRTClientEngineConfig) throws {
        AwsCommonRuntimeKit.initialize()
        self.maxConnectionsPerEndpoint = config.maxConnectionsPerEndpoint
        self.eventLoopGroup = eventLoopGroup
        let hostResolver = DefaultHostResolver(eventLoopGroup: eventLoopGroup, maxHosts: 8, maxTTL: 30)
        self.bootstrap = try ClientBootstrap(eventLoopGroup: eventLoopGroup, hostResolver: hostResolver)
        self.socketOptions = SocketOptions(socketType: .stream)
        let tlsContextOptions = TlsContextOptions()
        tlsContextOptions.setVerifyPeer(config.verifyPeer)
        self.tlsContextOptions = tlsContextOptions
        self.tlsContext = try TlsContext(options: tlsContextOptions, mode: .client)
        self.windowSize = config.windowSize
        self.logger = SwiftLogger(label: "CRTClientEngine")
        self.crtLogger = Logger(pipe: stdout, level: .none, allocator: defaultAllocator)
    }
    
    public required convenience init(eventLoopGroup: EventLoopGroup) throws {
        try self.init(eventLoopGroup: eventLoopGroup, config: CRTClientEngineConfig())
    }
    
    public convenience init() throws {
        try self.init(eventLoopGroup: EventLoopGroup(threadCount: 1))
    }
    
    private func createConnectionPool(endpoint: Endpoint) -> HttpClientConnectionManager {
        let tlsConnectionOptions = tlsContext.newConnectionOptions()
        let options = HttpClientConnectionOptions(clientBootstrap: bootstrap,
                                                  hostName: endpoint.host,
                                                  initialWindowSize: windowSize,
                                                  port: UInt16(endpoint.port),
                                                  proxyOptions: nil,
                                                  socketOptions: socketOptions,
                                                  tlsOptions: tlsConnectionOptions,
                                                  monitoringOptions: nil,
                                                  maxConnections: maxConnectionsPerEndpoint,
                                                  enableManualWindowManagement: false) // not using backpressure yet
        logger.debug("Creating connection pool for \(String(describing: endpoint.url?.absoluteString))" +
                        "with max connections: \(maxConnectionsPerEndpoint)")
        return HttpClientConnectionManager(options: options)
    }
    
    private func getOrCreateConnectionPool(endpoint: Endpoint) -> HttpClientConnectionManager {
        
        guard let connectionPool = connectionPools[endpoint] else {
            let newConnectionPool = createConnectionPool(endpoint: endpoint)
            connectionPools[endpoint] = newConnectionPool // save in dictionary
            return newConnectionPool
        }
        
        return connectionPool
    }
    
    public func executeWithClosure(request: SdkHttpRequest, completion: @escaping NetworkResult) {
        execute(request: request).then { (result) in
            completion(result)
        }
    }
    
    public func execute(request: SdkHttpRequest) -> Future<HttpResponse> {
        let isStreaming = { () -> Bool in
            switch request.body {
            case .stream: return true
            default: return false
            }
        }()
        let connectionMgr = getOrCreateConnectionPool(endpoint: request.endpoint)
        let httpResponseFuture: Future<HttpResponse> = connectionMgr.acquireConnection()
            .chained { (connectionResult) -> Future<HttpResponse> in
                self.logger.debug("Connection was acquired to: \(String(describing: request.endpoint.url?.absoluteString))")
                let (requestOptions, future) = isStreaming ?
                    self.makeHttpRequestStreamOptions(request): self.makeHttpRequestOptions(request)
                switch connectionResult {
                case .failure(let error):
                    future.fail(error)
                case .success(let connection):
                    let stream = connection.makeRequest(requestOptions: requestOptions)
                    stream.activate()
                    // map status code once call comes back
                    future.then { (responseResult) in
                        _ = responseResult.map { (response) -> HttpResponse in
                            self.logger.debug("Future of response came back with success: \(response)")
                            let statusCode = Int(stream.getResponseStatusCode())
                            response.statusCode = HttpStatusCode(rawValue: statusCode) ?? HttpStatusCode.notFound
                            return response
                        }
                    }
                }
                
                return future
            }
        return httpResponseFuture
    }
    
    public func close() {
        for (endpoint, value) in connectionPools {
            logger.debug("Connection to endpoint: \(String(describing: endpoint.url?.absoluteString)) is closing")
            value.closePendingConnections()
        }
    }
    
    public func makeHttpRequestStreamOptions(_ request: SdkHttpRequest) -> (HttpRequestOptions, Future<HttpResponse>) {
        let future = Future<HttpResponse>()
        let crtRequest = request.toHttpRequest(bufferSize: windowSize)
        let response = HttpResponse()
        
        var streamReader: StreamReader?
        if case let HttpBody.stream(unwrappedStream) = request.body,
           case let ByteStream.reader(reader) = unwrappedStream {
            streamReader = reader
        }
        
        let requestOptions = HttpRequestOptions(request: crtRequest) { [self] (stream, _, httpHeaders) in
            logger.debug("headers were received")
            response.statusCode = HttpStatusCode(rawValue: Int(stream.getResponseStatusCode()))
                ?? HttpStatusCode.notFound
            response.headers.addAll(httpHeaders: httpHeaders)
        } onIncomingHeadersBlockDone: { [self] (stream, _) in
            logger.debug("header block is done")
            response.statusCode = HttpStatusCode(rawValue: Int(stream.getResponseStatusCode()))
                ?? HttpStatusCode.notFound
        } onIncomingBody: { [self] (_, data) in
            logger.debug("incoming data")
            
            if let streamReader = streamReader {
                let byteBuffer = ByteBuffer(data: data)
                streamReader.write(buffer: byteBuffer)
            }
        } onStreamComplete: { [self] (_, error) in
            logger.debug("stream completed")
            if case let CRTError.crtError(unwrappedError) = error {
                if unwrappedError.errorCode != 0 {
                    logger.error("Response encountered an error: \(error)")
                    if let streamReader = streamReader {
                        streamReader.onError(error: ClientError.crtError(error))
                    }
                    future.fail(error)
                }
            }
            if let streamReader = streamReader {
                streamReader.isClosedForWrite = true
                response.body = .stream(.reader(streamReader))
            }
            future.fulfill(response)
        }
        
        return (requestOptions, future)
    }
    
    public func makeHttpRequestOptions(_ request: SdkHttpRequest) -> (HttpRequestOptions, Future<HttpResponse>) {
        let future = Future<HttpResponse>()
        let crtRequest = request.toHttpRequest(bufferSize: windowSize)
        
        let response = HttpResponse()
        var incomingData = Data()
        
        let requestOptions = HttpRequestOptions(request: crtRequest) { [self] (stream, _, httpHeaders) in
            logger.debug("headers were received")
            response.statusCode = HttpStatusCode(rawValue: Int(stream.getResponseStatusCode()))
                ?? HttpStatusCode.notFound
            response.headers.addAll(httpHeaders: httpHeaders)
        } onIncomingHeadersBlockDone: { [self] (stream, _) in
            logger.debug("header block is done")
            response.statusCode = HttpStatusCode(rawValue: Int(stream.getResponseStatusCode()))
                ?? HttpStatusCode.notFound
        } onIncomingBody: { [self] (_, data) in
            logger.debug("incoming data: \(data.count) bytes")
            incomingData.append(data)
        } onStreamComplete: { [self] (_, error) in
            logger.debug("stream completed")
            if case let CRTError.crtError(unwrappedError) = error {
                if unwrappedError.errorCode != 0 {
                    logger.error("Response encountered an error: \(error)")
                    future.fail(error)
                }
            }
            
            response.body = HttpBody.data(incomingData)
            future.fulfill(response)
        }
        
        return (requestOptions, future)
    }
    
    deinit {
        AwsCommonRuntimeKit.cleanUp()
    }
}
