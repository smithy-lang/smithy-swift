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
    actor SerialExecutor {
        private var logger: LogAgent

        private let windowSize: Int
        private let maxConnectionsPerEndpoint: Int
        private var connectionPools: [Endpoint: HTTPClientConnectionManager] = [:]
        private let sharedDefaultIO = SDKDefaultIO.shared

        init(config: CRTClientEngineConfig) {
            self.windowSize = config.windowSize
            self.maxConnectionsPerEndpoint = config.maxConnectionsPerEndpoint
            self.logger = SwiftLogger(label: "SerialExecutor")
        }

        func getOrCreateConnectionPool(endpoint: Endpoint) throws -> HTTPClientConnectionManager {
            guard let connectionPool = connectionPools[endpoint] else {
                let newConnectionPool = try createConnectionPool(endpoint: endpoint)
                connectionPools[endpoint] = newConnectionPool // save in dictionary
                return newConnectionPool
            }

            return connectionPool
        }

        private func createConnectionPool(endpoint: Endpoint) throws -> HTTPClientConnectionManager {
            let tlsConnectionOptions = TLSConnectionOptions(
                context: sharedDefaultIO.tlsContext,
                serverName: endpoint.host
            )

            let socketOptions = SocketOptions(socketType: .stream)
    #if os(iOS) || os(watchOS)
            socketOptions.connectTimeoutMs = 30_000
    #endif
            let options = HTTPClientConnectionOptions(
                clientBootstrap: sharedDefaultIO.clientBootstrap,
                hostName: endpoint.host,
                initialWindowSize: windowSize,
                port: UInt16(endpoint.port),
                proxyOptions: nil,
                socketOptions: socketOptions,
                tlsOptions: tlsConnectionOptions,
                monitoringOptions: nil,
                maxConnections: maxConnectionsPerEndpoint,
                enableManualWindowManagement: false
            ) // not using backpressure yet
            logger.debug("Creating connection pool for \(String(describing: endpoint.url?.absoluteString))" +
                         "with max connections: \(maxConnectionsPerEndpoint)")
            return try HTTPClientConnectionManager(options: options)
        }
    }

    public typealias StreamContinuation = CheckedContinuation<HttpResponse, Error>
    private var logger: LogAgent
    private let serialExecutor: SerialExecutor
    private let CONTENT_LENGTH_HEADER = "Content-Length"
    private let AWS_COMMON_RUNTIME = "AwsCommonRuntime"
    private let DEFAULT_STREAM_WINDOW_SIZE = 16 * 1024 * 1024 // 16 MB
    
    private let windowSize: Int
    private let maxConnectionsPerEndpoint: Int
    
    init(config: CRTClientEngineConfig = CRTClientEngineConfig()) {
        self.maxConnectionsPerEndpoint = config.maxConnectionsPerEndpoint
        self.windowSize = config.windowSize
        self.logger = SwiftLogger(label: "CRTClientEngine")
        self.serialExecutor = SerialExecutor(config: config)
    }
    
    public func execute(request: SdkHttpRequest) async throws -> HttpResponse {
        let connectionMgr = try await serialExecutor.getOrCreateConnectionPool(endpoint: request.endpoint)
        let connection = try await connectionMgr.acquireConnection()
        self.logger.debug("Connection was acquired to: \(String(describing: request.endpoint.url?.absoluteString))")
        return try await withCheckedThrowingContinuation({ (continuation: StreamContinuation) in
            do {
                let requestOptions = try makeHttpRequestStreamOptions(request, continuation)
                let stream = try connection.makeRequest(requestOptions: requestOptions)
                try stream.activate()
            } catch {
                continuation.resume(throwing: error)
            }
        })
    }
    
    public func makeHttpRequestStreamOptions(
        _ request: SdkHttpRequest,
        _ continuation: StreamContinuation
    ) throws -> HTTPRequestOptions {
        let response = HttpResponse()
        let crtRequest = try request.toHttpRequest()
        var responseData = Data()
        
        let makeStatusCode: (HTTPStream) -> HttpStatusCode = { stream in
            guard
                let statusCodeInt = try? stream.statusCode(),
                let statusCode = HttpStatusCode(rawValue: statusCodeInt)
            else { return .notFound }
            return statusCode
        }

        let requestOptions = HTTPRequestOptions(request: crtRequest) { [self] (stream, _, httpHeaders) in
            logger.debug("headers were received")
            response.statusCode = makeStatusCode(stream)
            response.headers.addAll(httpHeaders: httpHeaders)
        } onIncomingHeadersBlockDone: { [self] (stream, _) in
            logger.debug("header block is done")
            response.statusCode = makeStatusCode(stream)
        } onIncomingBody: { [self] (stream, data) in
            logger.debug("incoming data")
            response.statusCode = makeStatusCode(stream)
            responseData.append(data)
        } onStreamComplete: { [self] (stream, error) in
            logger.debug("stream completed")
            if let error = error, error.code != 0 {
                logger.error("Response encountered an error: \(error)")
                continuation.resume(throwing: CommonRunTimeError.crtError(error))
                return
            }
        
            response.body = .stream(.buffer(ByteBuffer(data: responseData)))
            response.statusCode = makeStatusCode(stream)

            continuation.resume(returning: response)
        }
        return requestOptions
    }
    
    public func close() async {
        // no-op
    }
}
