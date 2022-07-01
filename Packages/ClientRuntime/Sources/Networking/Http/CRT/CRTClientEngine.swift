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
    public typealias StreamContinuation = CheckedContinuation<HttpResponse, Error>
    private var logger: LogAgent
    private var connectionPools: [Endpoint: HttpClientConnectionManager] = [:]
    private let CONTENT_LENGTH_HEADER = "Content-Length"
    private let AWS_COMMON_RUNTIME = "AwsCommonRuntime"
    private let DEFAULT_STREAM_WINDOW_SIZE = 16 * 1024 * 1024 // 16 MB
    
    private let windowSize: Int
    private let maxConnectionsPerEndpoint: Int
    private let sharedDefaultIO: SDKDefaultIO = SDKDefaultIO.shared
    
    init(config: CRTClientEngineConfig = CRTClientEngineConfig()) {
        self.maxConnectionsPerEndpoint = config.maxConnectionsPerEndpoint
        self.windowSize = config.windowSize
        self.logger = SwiftLogger(label: "CRTClientEngine")
    }
    
    private func createConnectionPool(endpoint: Endpoint) -> HttpClientConnectionManager {
        let tlsConnectionOptions = SDKDefaultIO.shared.tlsContext.newConnectionOptions()
        do {
            try tlsConnectionOptions.setServerName(endpoint.host)
        } catch let err {
            logger.error("Server name was not able to be set in TLS Connection Options. TLS Negotiation will fail.")
            logger.error("Error: \(err.localizedDescription)")
        }
        let socketOptions = SocketOptions(socketType: .stream)
#if os(iOS) || os(watchOS)
        socketOptions.connectTimeoutMs = 30_000
#endif
        let options = HttpClientConnectionOptions(clientBootstrap: SDKDefaultIO.shared.clientBootstrap,
                                                  hostName: endpoint.host,
                                                  initialWindowSize: windowSize,
                                                  port: UInt16(endpoint.port),
                                                  proxyOptions: nil,
                                                  socketOptions: socketOptions,
                                                  tlsOptions: tlsConnectionOptions,
                                                  monitoringOptions: nil,
                                                  maxConnections: maxConnectionsPerEndpoint,
                                                  enableManualWindowManagement: false) // not using backpressure yet
        if let endpoint = endpoint.url?.absoluteString {
            logger.debug("Creating connection pool for \(endpoint)" +
                         " with max connections: \(maxConnectionsPerEndpoint)")
        } else {
            logger.debug("Creating connection pool with max connections: \(maxConnectionsPerEndpoint)")
        }
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
    
    public func execute(request: SdkHttpRequest) async throws -> HttpResponse {
        let connectionMgr = getOrCreateConnectionPool(endpoint: request.endpoint)
        let connection = try await connectionMgr.acquireConnection()
        self.logger.trace("Connection was acquired to: \(String(describing: request.endpoint.url?.absoluteString))")
        return try await withCheckedThrowingContinuation({ (continuation: StreamContinuation) in
            let requestOptions = makeHttpRequestStreamOptions(request, continuation)
            let stream = connection.makeRequest(requestOptions: requestOptions)
            stream.activate()
        })

    }
    
    public func close() {
        for (endpoint, value) in connectionPools {
            logger.trace("Connection to endpoint: \(String(describing: endpoint.url?.absoluteString)) is closing")
            value.closePendingConnections()
        }
    }
    
    public func makeHttpRequestStreamOptions(_ request: SdkHttpRequest, _ continuation: StreamContinuation) -> HttpRequestOptions {
        let response = HttpResponse()
        let crtRequest = request.toHttpRequest(bufferSize: windowSize)
        let streamReader: StreamReader = DataStreamReader()
        
        let requestOptions = HttpRequestOptions(request: crtRequest) { [self] (stream, _, httpHeaders) in
            logger.trace("headers were received")
            response.statusCode = HttpStatusCode(rawValue: Int(stream.statusCode)) ?? HttpStatusCode.notFound
            response.headers.addAll(httpHeaders: httpHeaders)
        } onIncomingHeadersBlockDone: { [self] (stream, _) in
            logger.trace("header block is done")
            response.statusCode = HttpStatusCode(rawValue: Int(stream.statusCode)) ?? HttpStatusCode.notFound
        } onIncomingBody: { [self] (stream, data) in
            logger.trace("incoming data")
            response.statusCode = HttpStatusCode(rawValue: Int(stream.statusCode)) ?? HttpStatusCode.notFound
            let byteBuffer = ByteBuffer(data: data)
            streamReader.write(buffer: byteBuffer)
        } onStreamComplete: { [self] (stream, error) in
            logger.trace("stream completed")
            streamReader.hasFinishedWriting = true
            if case let CRTError.crtError(unwrappedError) = error {
                if unwrappedError.errorCode != 0 {
                    logger.error("Response encountered an error: \(error)")
                    streamReader.onError(error: ClientError.crtError(error))
                    continuation.resume(throwing: error)
                    return
                }
            }
            
            response.body = .stream(.reader(streamReader))
           
            response.statusCode = HttpStatusCode(rawValue: Int(stream.statusCode)) ?? HttpStatusCode.notFound
            
            continuation.resume(returning: response)
        }
        return requestOptions
    }
}
