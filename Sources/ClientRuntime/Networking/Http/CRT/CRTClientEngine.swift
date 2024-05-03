/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import AwsCommonRuntimeKit
import class Foundation.DispatchQueue
#if os(Linux)
import Glibc
#else
import Darwin
#endif

public class CRTClientEngine: HTTPClient {
    actor SerialExecutor {

        /// Stores the common properties of requests that should share a HTTP connection, such that requests
        /// with equal `ConnectionID` values should be pooled together.
        ///
        /// Used as a dictionary key for storing CRT connection managers once they have been created.
        /// When a new request is made, a connection manager is reused if it matches the request's scheme,
        /// host, and port.
        private struct ConnectionPoolID: Hashable {
            private let protocolType: ProtocolType?
            private let host: String
            private let port: Int16

            init(endpoint: Endpoint) {
                self.protocolType = endpoint.protocolType
                self.host = endpoint.host
                self.port = endpoint.port
            }
        }

        private var logger: LogAgent

        private let windowSize: Int
        private let maxConnectionsPerEndpoint: Int
        private var connectionPools: [ConnectionPoolID: HTTPClientConnectionManager] = [:]
        private var http2ConnectionPools: [ConnectionPoolID: HTTP2StreamManager] = [:]
        private let sharedDefaultIO = SDKDefaultIO.shared
        private let connectTimeoutMs: UInt32?
        private let crtTLSOptions: CRTClientTLSOptions?
        private let socketTimeout: UInt32?

        init(config: CRTClientEngineConfig) {
            self.windowSize = config.windowSize
            self.maxConnectionsPerEndpoint = config.maxConnectionsPerEndpoint
            self.logger = SwiftLogger(label: "SerialExecutor")
            self.connectTimeoutMs = config.connectTimeoutMs
            self.crtTLSOptions = config.crtTlsOptions
            self.socketTimeout = config.socketTimeout
        }

        func getOrCreateConnectionPool(endpoint: Endpoint) throws -> HTTPClientConnectionManager {
            let poolID = ConnectionPoolID(endpoint: endpoint)
            guard let connectionPool = connectionPools[poolID] else {
                let newConnectionPool = try createConnectionPool(endpoint: endpoint)
                connectionPools[poolID] = newConnectionPool // save in dictionary
                return newConnectionPool
            }
            return connectionPool
        }

        func getOrCreateHTTP2ConnectionPool(endpoint: Endpoint) throws -> HTTP2StreamManager {
            let poolID = ConnectionPoolID(endpoint: endpoint)
            guard let connectionPool = http2ConnectionPools[poolID] else {
                let newConnectionPool = try createHTTP2ConnectionPool(endpoint: endpoint)
                http2ConnectionPools[poolID] = newConnectionPool // save in dictionary
                return newConnectionPool
            }
            return connectionPool
        }

        private func createConnectionPool(endpoint: Endpoint) throws -> HTTPClientConnectionManager {
            let tlsConnectionOptions = endpoint.protocolType == .https ? TLSConnectionOptions(
                context: self.crtTLSOptions?.resolveContext() ?? sharedDefaultIO.tlsContext,
                serverName: endpoint.host
            ) : nil

            var socketOptions = SocketOptions(socketType: .stream)
#if os(iOS) || os(watchOS)
            socketOptions.connectTimeoutMs = self.connectTimeoutMs ?? 30_000
#else
            if let timeout = self.connectTimeoutMs {
                socketOptions.connectTimeoutMs = timeout
            }
#endif
            let httpMonitoringOptions = HTTPMonitoringOptions(
                minThroughputBytesPerSecond: 1,
                // 0 means infinite; sockets won't timeout if no value was provided in config.
                allowableThroughputFailureInterval: socketTimeout ?? 0
            )

            let options = HTTPClientConnectionOptions(
                clientBootstrap: sharedDefaultIO.clientBootstrap,
                hostName: endpoint.host,
                initialWindowSize: windowSize,
                port: UInt32(endpoint.port),
                proxyOptions: nil,
                socketOptions: socketOptions,
                tlsOptions: tlsConnectionOptions,
                monitoringOptions: httpMonitoringOptions,
                maxConnections: maxConnectionsPerEndpoint,
                enableManualWindowManagement: false
            ) // not using backpressure yet
            logger.debug("""
            Creating connection pool for \(String(describing: endpoint.host)) \
            with max connections: \(maxConnectionsPerEndpoint)
            """)
            return try HTTPClientConnectionManager(options: options)
        }

        private func createHTTP2ConnectionPool(endpoint: Endpoint) throws -> HTTP2StreamManager {
            var socketOptions = SocketOptions(socketType: .stream)
#if os(iOS) || os(watchOS)
            socketOptions.connectTimeoutMs = self.connectTimeoutMs ?? 30_000
#else
            if let timeout = self.connectTimeoutMs {
                socketOptions.connectTimeoutMs = timeout
            }
#endif
            let tlsConnectionOptions = TLSConnectionOptions(
                context: self.crtTLSOptions?.resolveContext() ?? sharedDefaultIO.tlsContext,
                alpnList: [ALPNProtocol.http2.rawValue],
                serverName: endpoint.host
            )

            let options = HTTP2StreamManagerOptions(
                clientBootstrap: sharedDefaultIO.clientBootstrap,
                hostName: endpoint.host,
                port: UInt32(endpoint.port),
                maxConnections: maxConnectionsPerEndpoint,
                socketOptions: socketOptions,
                tlsOptions: tlsConnectionOptions,
                enableStreamManualWindowManagement: false
            )
            logger.debug("""
            Creating connection pool for \(String(describing: endpoint.host)) \
            with max connections: \(maxConnectionsPerEndpoint)
            """)

            return try HTTP2StreamManager(options: options)
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

    // swiftlint:disable:function_body_length
    public func send(request: SdkHttpRequest) async throws -> HttpResponse {
        // Boolean flag for each independent request's continuation.
        let continuationFlag = ContinuationFlag()

        let connectionMgr = try await serialExecutor.getOrCreateConnectionPool(endpoint: request.endpoint)
        let connection = try await connectionMgr.acquireConnection()

        self.logger.debug("Connection was acquired to: \(String(describing: request.endpoint.url?.absoluteString))")
        switch connection.httpVersion {
        case .version_1_1:
            self.logger.debug("Using HTTP/1.1 connection")
            let crtRequest = try request.toHttpRequest()
            return try await withCheckedThrowingContinuation { (continuation: StreamContinuation) in
                let requestOptions = makeHttpRequestStreamOptions(
                    continuationFlag: continuationFlag,
                    request: crtRequest,
                    continuation: continuation
                )
                do {
                    let stream = try connection.makeRequest(requestOptions: requestOptions)
                    try stream.activate()
                    if request.isChunked {
                        Task {
                            do {
                                guard let http1Stream = stream as? HTTP1Stream else {
                                    throw StreamError.notSupported(
                                        "HTTP1Stream should be used with an HTTP/1.1 connection!"
                                    )
                                }
                                let body = request.body

                                guard case .stream(let stream) = body, stream.isEligibleForAwsChunkedStreaming() else {
                                    throw ByteStreamError.invalidStreamTypeForChunkedBody(
                                        "The stream is not eligible for AWS chunked streaming or is not a stream type!"
                                    )
                                }

                                guard let awsChunkedStream = stream as? AWSChunkedStream else {
                                    throw ByteStreamError.streamDoesNotConformToAwsChunkedStream(
                                        "Stream does not conform to AwsChunkedStream! Type is \(stream)."
                                    )
                                }

                                var hasMoreChunks = true
                                while hasMoreChunks {
                                    // Process the first chunk and determine if there are more to send
                                    hasMoreChunks = try await awsChunkedStream.chunkedReader.processNextChunk()

                                    if !hasMoreChunks {
                                        // Send the final chunk
                                        let finalChunk = try await awsChunkedStream.chunkedReader.getFinalChunk()
                                        try await http1Stream.writeChunk(chunk: finalChunk, endOfStream: true)
                                    } else {
                                        let currentChunkBody = awsChunkedStream.chunkedReader.getCurrentChunkBody()
                                        if !currentChunkBody.isEmpty {
                                            try await http1Stream.writeChunk(
                                                chunk: awsChunkedStream.chunkedReader.getCurrentChunk(),
                                                endOfStream: false
                                            )
                                        }
                                    }
                                }
                            } catch {
                                logger.error(error.localizedDescription)
                                Task {
                                    await self.safeResumeThrowContinuation(
                                        continuationFlag: continuationFlag,
                                        continuation: continuation,
                                        error: error
                                    )
                                }
                            }
                        }
                    }
                } catch {
                    logger.error(error.localizedDescription)
                    Task {
                        await self.safeResumeThrowContinuation(
                            continuationFlag: continuationFlag,
                            continuation: continuation,
                            error: error
                        )
                    }
                }
            }
        case .version_2:
            self.logger.debug("Using HTTP/2 connection")
            let crtRequest = try request.toHttp2Request()
            return try await withCheckedThrowingContinuation { (continuation: StreamContinuation) in
                let requestOptions = makeHttpRequestStreamOptions(
                    continuationFlag: continuationFlag,
                    request: crtRequest,
                    continuation: continuation,
                    http2ManualDataWrites: true
                )
                Task {
                    let stream: HTTP2Stream
                    do {
                        // swiftlint:disable:next force_cast
                        stream = try connection.makeRequest(requestOptions: requestOptions) as! HTTP2Stream
                        try stream.activate()
                    } catch {
                        logger.error(error.localizedDescription)
                        await self.safeResumeThrowContinuation(
                            continuationFlag: continuationFlag,
                            continuation: continuation,
                            error: error
                        )
                        return
                    }

                    // At this point, continuation is resumed when the initial headers are received
                    // it is now safe to write the body
                    // writing is done in a separate task to avoid blocking the continuation
                    Task { [logger] in
                        do {
                            try await stream.write(body: request.body)
                        } catch {
                            logger.error(error.localizedDescription)
                        }
                    }
                }
            }
        case .unknown:
            fatalError("Unknown HTTP version")
        }
    }
    // swiftlint:enable:function_body_length

    // Forces an Http2 request that uses CRT's `HTTP2StreamManager`.
    // This may be removed or improved as part of SRA work and CRT adapting to SRA for HTTP.
    func executeHTTP2Request(request: SdkHttpRequest) async throws -> HttpResponse {
        // Boolean flag for each new request's continuation.
        let continuationFlag = ContinuationFlag()

        let connectionMgr = try await serialExecutor.getOrCreateHTTP2ConnectionPool(endpoint: request.endpoint)

        self.logger.debug("Using HTTP/2 connection")
        let crtRequest = try request.toHttp2Request()

        return try await withCheckedThrowingContinuation { (continuation: StreamContinuation) in
            let requestOptions = makeHttpRequestStreamOptions(
                continuationFlag: continuationFlag,
                request: crtRequest,
                continuation: continuation,
                http2ManualDataWrites: true
            )
            Task {
                let stream: HTTP2Stream
                do {
                    stream = try await connectionMgr.acquireStream(requestOptions: requestOptions)
                } catch {
                    logger.error(error.localizedDescription)
                    Task {
                        await self.safeResumeThrowContinuation(
                            continuationFlag: continuationFlag,
                            continuation: continuation,
                            error: error
                        )
                    }
                    return
                }

                // At this point, continuation is resumed when the initial headers are received
                // it is now safe to write the body
                // writing is done in a separate task to avoid blocking the continuation
                Task { [logger] in
                    do {
                        try await stream.write(body: request.body)
                    } catch {
                        logger.error(error.localizedDescription)
                    }
                }
            }
        }
    }

    /// Creates a `HTTPRequestOptions` object that can be used to make a HTTP request
    /// - Parameters:
    ///   - continuationFlag: The actor that wraps the boolean flag used to track continuation resume status
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
        continuationFlag: ContinuationFlag,
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
            Task {
                await self.safeResumeReturnContinuation(
                    continuationFlag: continuationFlag,
                    continuation: continuation,
                    response: response
                )
            }
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
                Task {
                    await self.safeResumeThrowContinuation(
                        continuationFlag: continuationFlag,
                        continuation: continuation,
                        error: error
                    )
                }
            }

            // closing the stream is required to signal to the caller that the response is complete
            // and no more data will be received in this stream
            stream.close()
        }

        requestOptions.http2ManualDataWrites = http2ManualDataWrites

        response.body = .stream(stream)
        return requestOptions
    }

    actor ContinuationFlag {
        var continuationResumed = false
        public func setFlag(val: Bool) {
            continuationResumed = val
        }
    }

    private func safeResumeThrowContinuation (
        continuationFlag: ContinuationFlag,
        continuation: StreamContinuation,
        error: Error
    ) async {
        if !(await continuationFlag.continuationResumed) {
            await continuationFlag.setFlag(val: true)
            continuation.resume(throwing: error)
        }
    }

    private func safeResumeReturnContinuation(
        continuationFlag: ContinuationFlag,
        continuation: StreamContinuation,
        response: HttpResponse
    ) async {
        if !(await continuationFlag.continuationResumed) {
            await continuationFlag.setFlag(val: true)
            continuation.resume(returning: response)
        }
    }
}
