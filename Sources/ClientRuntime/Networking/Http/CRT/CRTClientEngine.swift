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
            return try await withCheckedThrowingContinuation({ (continuation: StreamContinuation) in
                Task {
                    do {
                        let requestOptions = try makeHttpRequestStreamOptions(request: request, continuation: continuation)
                        let stream = try connection.makeRequest(requestOptions: requestOptions)
                        try stream.activate()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            })
        case .version_2:
            return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<HttpResponse, Error>) in
                Task {
                    do {
                        let requestOptions = try makeHttpRequestStreamOptions(request: request,
                                                                              http2ManualDataWrites: true,
                                                                              continuation: continuation)
                        let h2Stream = try connection.makeRequest(requestOptions: requestOptions) as! HTTP2Stream
                        try h2Stream.activate()
                        try await h2Stream.write(body: request.body)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            })
        case .unknown:
            fatalError("Unknown HTTP version")
        }

    }

    public func makeHttpRequestStreamOptions(
        request: SdkHttpRequest,
        http2ManualDataWrites: Bool = false,
        continuation: CheckedContinuation<HttpResponse, Error>
    ) throws -> HTTPRequestOptions {
        let response = HttpResponse()
        let crtRequest = try request.toHttpRequest()
        let streamReader: StreamReader = DataStreamReader()

        let makeStatusCode: (UInt32) -> HttpStatusCode = { statusCode in
            self.logger.debug("Response status code: \(statusCode)")
            return HttpStatusCode(rawValue: Int(statusCode)) ?? .notFound
         }

        var requestOptions = HTTPRequestOptions(request: crtRequest) { statusCode, headers in
            response.statusCode = makeStatusCode(statusCode)
            response.headers.addAll(headers: Headers(httpHeaders: headers))
        } onResponse: { statusCode, headers in
            response.statusCode = makeStatusCode(statusCode)
            response.headers.addAll(headers: Headers(httpHeaders: headers))
            // resume the continuation as soon as the response headers are received
            // this allows the user to start reading the response body without waiting for the entire body to be received
            continuation.resume(returning: response)
        } onIncomingBody: { bodyChunk in
            let byteBuffer = ByteBuffer(data: bodyChunk)
            streamReader.write(buffer: byteBuffer)
        } onTrailer: { headers in
            response.headers.addAll(headers: Headers(httpHeaders: headers))
        } onStreamComplete: { result in
            streamReader.hasFinishedWriting = true
            switch result {
            case .success(let statusCode):
                response.statusCode = makeStatusCode(statusCode)
            case .failure(let error):
                self.logger.error("Response encountered an error: \(error)")
                streamReader.onError(error: .crtError(error))
            }
        }

        requestOptions.http2ManualDataWrites = http2ManualDataWrites
        response.body = .stream(.reader(streamReader))
        return requestOptions
    }
}

extension HTTP2Stream {
    /// Writes the body to the HTTP2Stream
    /// - Parameter body: The body to write to the stream
    func write(body: HttpBody) async throws {
        switch body {
        case .data(let data):
            guard let data = data else {
                break
            }
            try await writeData(data: data, endOfStream: false)
        case .stream(let stream):
            switch stream {
            case .buffer(let buffer):
                try await writeData(data: buffer.getData(), endOfStream: false)
            case .reader(let reader):
                while !reader.hasFinishedWriting {
                    guard let data = try await reader.read(upToCount: nil) else {
                        continue
                    }
                    try await writeData(data: data, endOfStream: false)
                }
            }
        case .none:
            break
        }

        try await writeData(data: .init(), endOfStream: true)
    }
}
