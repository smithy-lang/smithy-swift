//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.

import AwsCommonRuntimeKit
import Logging

class CRTClientEngine: HttpClientEngine {
    
    private var logger: LogAgent
    private var connectionPools: [Endpoint: HttpClientConnectionManager] = [:]
    private let HOST_HEADER = "Host"
    private let CONTENT_LENGTH_HEADER = "Content-Length"
    private let CONNECTION_HEADER = "Connection"
    private let KEEP_ALIVE = "keep-alive"
    private let AWS_COMMON_RUNTIME = "AwsCommonRuntime"
    private let DEFAULT_STREAM_WINDOW_SIZE = 16 * 1024 * 1024 // 16 MB
    
    private let bootstrap: ClientBootstrap
    private let socketOptions: SocketOptions
    private let tlsContextOptions: TlsContextOptions
    private let tlsContext: TlsContext
    private let windowSize: Int
    private let maxConnectionsPerEndpoint: Int
    
    public init(config: CRTClientEngineConfig = CRTClientEngineConfig()) throws {
        AwsCommonRuntimeKit.initialize()
        self.maxConnectionsPerEndpoint = config.maxConnectionsPerEndpoint
        let elg = EventLoopGroup(threadCount: 1)
        let hostResolver = DefaultHostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30)
        self.bootstrap = try ClientBootstrap(eventLoopGroup: elg, hostResolver: hostResolver)
        self.socketOptions = SocketOptions(socketType: .stream)
        let tlsContextOptions = TlsContextOptions()
        tlsContextOptions.setVerifyPeer(config.verifyPeer)
        self.tlsContextOptions = tlsContextOptions
        self.tlsContext = try TlsContext(options: tlsContextOptions, mode: .client)
        self.windowSize = config.windowSize
        self.logger = Logger(label: "CRTClientEngine")
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
                                                  enableManualWindowManagement: true)
        logger.debug("Creating connection pool for \(endpoint.urlString)" +
                        "with max connections: \(maxConnectionsPerEndpoint)")
        return HttpClientConnectionManager(options: options)
    }
    
    private func getOrCreateConnectionPool(endpoint: Endpoint) -> HttpClientConnectionManager {
        
        guard let connectionPool = connectionPools[endpoint] else {
            let newConnectionPool = createConnectionPool(endpoint: endpoint)
            connectionPools[endpoint] = newConnectionPool //save in dictionary
            return newConnectionPool
        }
        
        return connectionPool
    }
    
    private func addHttpHeaders(endpoint: Endpoint, request: SdkHttpRequest) -> HttpRequest {
        
        var headers = request.headers
        headers.update(name: HOST_HEADER, value: endpoint.host)
        headers.update(name: CONNECTION_HEADER, value: KEEP_ALIVE)
        
        let contentLength: Int64 = {
            switch request.body {
            case .data(let data):
                return Int64(data?.count ?? 0)
            case .stream(let stream):
                if let length = stream?.inputByteBuffer?.length {
                    return length
                } else {
                    return 0
                }
            case .none:
                return 0
            }
        }()
        
        headers.update(name: CONTENT_LENGTH_HEADER, value: "\(contentLength)")
        
        request.headers = headers
        return request.toHttpRequest()
    }
    
    public func execute(request: SdkHttpRequest, completion: @escaping NetworkResult) {
        let connectionMgr = getOrCreateConnectionPool(endpoint: request.endpoint)
        connectionMgr.acquireConnection().then { [self] (result) in
            logger.debug("connection was acquired to: \(request.endpoint.urlString)")
            switch result {
            case .success(let connection):
                let (requestOptions, future) = makeHttpRequestOptions(request)
                let stream = connection.makeRequest(requestOptions: requestOptions)
                stream.activate()
                future.then { (result) in
                    switch result {
                    case .success(let response):
                        logger.debug("Future of response came back with success: \(response)")
                        let statusCode = Int(stream.getResponseStatusCode())
                        response.statusCode = HttpStatusCode(rawValue: statusCode) ?? HttpStatusCode.notFound
                        completion(.success(response))
                    case .failure(let error):
                        logger.error("Future of response came back with an error: \(error)")
                        completion(.failure(error))
                    }
                    
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
    }
    
    public func close() {
        for (endpoint, value) in connectionPools {
            logger.debug("connection to endpoint: \(endpoint.urlString)")
            value.closePendingConnections()
        }
    }
    
    public func makeHttpRequestOptions(_ request: SdkHttpRequest) -> (HttpRequestOptions, Future<HttpResponse>) {
        let future = Future<HttpResponse>()
        let requestWithHeaders = addHttpHeaders(endpoint: request.endpoint, request: request)
        
        let response = HttpResponse()
        let incomingByteBuffer = ByteBuffer(size: 0)
        var stream: StreamSource?
        if case let HttpBody.stream(unwrappedStream) = request.body {
            stream = unwrappedStream
            stream?.outputByteBuffer = incomingByteBuffer
        }
        let requestOptions = HttpRequestOptions(request: requestWithHeaders) { [self] (stream, _, httpHeaders) in
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
            incomingByteBuffer.put(data)
            if let stream = stream {
                stream.receiveData(streamStatus: .receivedData, byteBuffer: incomingByteBuffer, error: nil)
            }
        } onStreamComplete: { [self] (_, error) in
            logger.debug("stream completed")
            if case let CRTError.crtError(unwrappedError) = error {
                if unwrappedError.errorCode != 0 {
                    logger.error("Response encountered an error: \(error)")
                    if let stream = stream {
                        stream.receiveData(streamStatus: .errorOccurred,
                                           byteBuffer: incomingByteBuffer,
                                           error: StreamError.unknown(error))
                    }
                    future.fail(error)
                }
            }
            if let stream = stream {
                stream.receiveData(streamStatus: .streamEnded, byteBuffer: incomingByteBuffer, error: nil)
            }
            response.body = {
                switch request.body {
                case .data:
                    return HttpBody.data(incomingByteBuffer.toData())
                case .stream:
                    return HttpBody.stream(stream)
                case .none:
                    return HttpBody.none
                }
            }()
                
            future.fulfill(response)
        }
        
        return (requestOptions, future)
    }
    
    deinit {
        AwsCommonRuntimeKit.cleanUp()
    }
}
