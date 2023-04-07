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

            var socketOptions = SocketOptions(socketType: .stream)
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
        switch connection.httpVersion {
        case .version_1_1:
            self.logger.debug("Using HTTP/1.1 connection")
            let crtRequest = try request.toHttpRequest()
            return try await withCheckedThrowingContinuation { (continuation: StreamContinuation) in
                let requestOptions = makeHttpRequestStreamOptions(request: crtRequest,
                                                                  continuation: continuation)
                do {
                    let stream = try connection.makeRequest(requestOptions: requestOptions)
                    try stream.activate()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        case .version_2:
            self.logger.debug("Using HTTP/2 connection")
            let crtRequest = try request.toHttp2Request()
            return try await withCheckedThrowingContinuation { (continuation: StreamContinuation) in
                let requestOptions = makeHttpRequestStreamOptions(request: crtRequest,
                                                                  continuation: continuation,
                                                                  http2ManualDataWrites: true)
                let stream: HTTP2Stream
                do {
                    stream = try connection.makeRequest(requestOptions: requestOptions) as! HTTP2Stream
                    try stream.activate()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                // At this point, continuation is resumed when the initial headers are received
                // it is now safe to write the body
                // writing is done in a separate task to avoid blocking the continuation
                Task {
                    do {
                        try await stream.write(body: request.body)
                    } catch {
                        self.logger.error(error.localizedDescription)
                    }
                }
            }
        case .unknown:
            fatalError("Unknown HTTP version")
        }
    }

    /// Creates a `HTTPRequestOptions` object that can be used to make a HTTP request
    /// - Parameters:
    ///   - request: The `HTTPRequestBase` object that contains the request information
    ///   - continuation: The continuation that will be resumed when the request is complete
    ///   - http2ManualDataWrites: Whether or not the request is using HTTP/2 manual data writes, defaults to `false`
    ///     If set to false, HTTP/2 manual data writes will be disabled and result in a runtime error on writing on the
    ///     HTTP/2 stream
    ///     If set to true, HTTP/2 manual data writes will be enabled, which will allow the manual writing on the HTTP/2
    ///     stream. Also, if the request body is specified, the body will be first written to the stream followed by
    ///     the manual writes.
    /// - Returns: A `HTTPRequestOptions` object that can be used to make a HTTP request
    private func makeHttpRequestStreamOptions(
        request: HTTPRequestBase,
        continuation: StreamContinuation,
        http2ManualDataWrites: Bool = false
    ) -> HTTPRequestOptions {
        let response = HttpResponse()
        let stream = BufferedStream()

        let makeStatusCode: (UInt32) -> HttpStatusCode = { statusCode in
            HttpStatusCode(rawValue: Int(statusCode)) ?? .notFound
        }

        var requestOptions = HTTPRequestOptions(request: request) { statusCode, headers in
            self.logger.debug("Interim response received")
            response.statusCode = makeStatusCode(statusCode)
            response.headers.addAll(headers: Headers(httpHeaders: headers))
        } onResponse: { statusCode, headers in
            self.logger.debug("Main headers received")
            response.statusCode = makeStatusCode(statusCode)
            response.headers.addAll(headers: Headers(httpHeaders: headers))

            // resume the continuation as soon as we have all the initial headers
            // this allows callers to start reading the response as it comes in
            // instead of waiting for the entire response to be received
            continuation.resume(returning: response)
        } onIncomingBody: { bodyChunk in
            self.logger.debug("Body chunk received")
            do {
                try stream.write(contentsOf: bodyChunk)
            } catch {
                self.logger.error("Failed to write to stream: \(error)")
            }
        } onTrailer: { headers in
            self.logger.debug("Trailer headers received")
            response.headers.addAll(headers: Headers(httpHeaders: headers))
        } onStreamComplete: { result in
            self.logger.debug("Request/response completed")
            switch result {
            case .success(let statusCode):
                response.statusCode = makeStatusCode(statusCode)
            case .failure(let error):
                self.logger.error("Response encountered an error: \(error)")
            }

            do {
                // closing the stream is required to signal to the caller that the response is complete
                // and no more data will be received in this stream
                try stream.close()
            } catch {
                self.logger.error("Failed to close stream: \(error)")
            }
        }

        requestOptions.http2ManualDataWrites = http2ManualDataWrites

        response.body = .stream(stream)
        return requestOptions
    }
}
