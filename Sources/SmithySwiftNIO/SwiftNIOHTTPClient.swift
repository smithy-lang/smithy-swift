//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AsyncHTTPClient
import NIOCore
import NIOHTTP1
import NIOPosix
import NIOSSL
import Smithy
import SmithyHTTPAPI
import SmithyHTTPClientAPI
import SmithyStreams
import SmithyTelemetryAPI
import struct Foundation.Date
import struct Foundation.URLComponents
import struct Foundation.URLQueryItem

/// AsyncHTTPClient-based HTTP client implementation that conforms to SmithyHTTPAPI.HTTPClient
/// This implementation is thread-safe and supports concurrent request execution.
public final class SwiftNIOHTTPClient: SmithyHTTPAPI.HTTPClient {
    public static let noOpSwiftNIOHTTPClientTelemetry =
        SmithyHTTPClientAPI.HttpTelemetry(
        httpScope: "SwiftNIOHTTPClient",
        telemetryProvider: SmithyTelemetryAPI.DefaultTelemetry.provider
    )

    private let client: AsyncHTTPClient.HTTPClient
    private let config: SmithyHTTPClientAPI.HTTPClientConfiguration
    private let tlsConfiguration: SwiftNIOHTTPClientTLSOptions?
    private let allocator: ByteBufferAllocator

    /// HTTP Client Telemetry
    private let telemetry: SmithyHTTPClientAPI.HttpTelemetry

    /// Logger for HTTP-related events.
    private var logger: LogAgent

    /// Creates a new `SwiftNIOHTTPClient`.
    ///
    /// The client is created with its own internal `AsyncHTTPClient`,
    /// which is configured with system defaults.
    /// - Parameters:
    ///   - httpClientConfiguration: The configuration to use for the
    ///     client's `AsyncHTTPClient` setup.
    ///   - eventLoopGroup: The `EventLoopGroup` that the ``HTTPClient`` will use.
    public init(
        httpClientConfiguration: SmithyHTTPClientAPI.HTTPClientConfiguration,
        eventLoopGroup: (any NIOCore.EventLoopGroup)? = nil
    ) {
        self.config = httpClientConfiguration
        self.telemetry = httpClientConfiguration.telemetry ??
            SwiftNIOHTTPClient.noOpSwiftNIOHTTPClientTelemetry
        self.logger = self.telemetry.loggerProvider.getLogger(
            name: "SwiftNIOHTTPClient"
        )
        self.tlsConfiguration = httpClientConfiguration.tlsConfiguration as? SwiftNIOHTTPClientTLSOptions
        self.allocator = ByteBufferAllocator()

        var clientConfig = AsyncHTTPClient.HTTPClient.Configuration.from(
            httpClientConfiguration: httpClientConfiguration
        )

        // Configure TLS if options are provided
        if let tlsOptions = tlsConfiguration {
            do {
                clientConfig.tlsConfiguration = try tlsOptions.makeNIOSSLConfiguration()
            } catch {
                // Log TLS configuration error but continue with default TLS settings
                self.logger.error(
                    "Failed to configure TLS: \(String(describing: error)). Using default TLS configuration."
                )
            }
        }

        if let eventLoopGroup {
            self.client = AsyncHTTPClient.HTTPClient(
                eventLoopGroup: eventLoopGroup,
                configuration: clientConfig
            )
        } else {
            self.client = AsyncHTTPClient.HTTPClient(configuration: clientConfig)
        }
    }

    deinit {
        try? client.syncShutdown()
    }

    public func send(
        request: SmithyHTTPAPI.HTTPRequest
    ) async throws -> SmithyHTTPAPI.HTTPResponse {
        let telemetryContext = telemetry.contextManager.current()
        let tracer = telemetry.tracerProvider.getTracer(
            scope: telemetry.tracerScope
        )

        // START - smithy.client.http.requests.queued_duration
        let queuedStart = Date().timeIntervalSinceReferenceDate
        let span = tracer.createSpan(
            name: telemetry.spanName,
            initialAttributes: telemetry.spanAttributes,
            spanKind: SpanKind.internal,
            parentContext: telemetryContext
        )
        defer {
            span.end()
        }

        // START - smithy.client.http.connections.acquire_duration
        let acquireConnectionStart = Date().timeIntervalSinceReferenceDate

        // Convert Smithy HTTPRequest to AsyncHTTPClient HTTPClientRequest
        let nioRequest = try await makeNIORequest(from: request)

        let acquireConnectionEnd = Date().timeIntervalSinceReferenceDate
        telemetry.connectionsAcquireDuration.record(
            value: acquireConnectionEnd - acquireConnectionStart,
            attributes: Attributes(),
            context: telemetryContext)
        // END - smithy.client.http.connections.acquire_duration

        let queuedEnd = acquireConnectionEnd
        telemetry.requestsQueuedDuration.record(
            value: queuedEnd - queuedStart,
            attributes: Attributes(),
            context: telemetryContext
        )
        // END - smithy.client.http.requests.queued_duration

        // Update connection and request usage metrics
        telemetry.updateHTTPMetricsUsage { httpMetricsUsage in
            // TICK - smithy.client.http.connections.limit
            // Note: AsyncHTTPClient doesn't expose connection pool
            // configuration publicly
            httpMetricsUsage.connectionsLimit = 0

            // TICK - smithy.client.http.connections.usage
            // Note: AsyncHTTPClient doesn't expose current connection counts
            httpMetricsUsage.acquiredConnections = 0
            httpMetricsUsage.idleConnections = 0

            // TICK - smithy.client.http.requests.usage
            httpMetricsUsage.inflightRequests = httpMetricsUsage.acquiredConnections
            httpMetricsUsage.queuedRequests = httpMetricsUsage.idleConnections
        }

        // DURATION - smithy.client.http.connections.uptime
        let connectionUptimeStart = acquireConnectionEnd
        defer {
            telemetry.connectionsUptime.record(
                value: Date().timeIntervalSinceReferenceDate - connectionUptimeStart,
                attributes: Attributes(),
                context: telemetryContext
            )
        }

        let httpMethod = request.method.rawValue
        let url = request.destination.url
        logger.debug("SwiftNIOHTTPClient(\(httpMethod) \(String(describing: url))) started")
        logBodyDescription(request.body)

        do {
            let timeout: TimeAmount = .seconds(Int64(config.socketTimeout))
            let nioResponse = try await client.execute(nioRequest, timeout: timeout)

            // Convert NIO response to Smithy HTTPResponse
            let statusCode = HTTPStatusCode(
                rawValue: Int(nioResponse.status.code)
            ) ?? .insufficientStorage
            var headers = Headers()
            for (name, value) in nioResponse.headers {
                headers.add(name: name, value: value)
            }

            let body = await SwiftNIOHTTPClientStreamBridge.convertResponseBody(
                from: nioResponse
            )

            let response = HTTPResponse(
                headers: headers,
                body: body,
                statusCode: statusCode
            )
            logger.debug("SwiftNIOHTTPClient(\(httpMethod) \(String(describing: url))) succeeded")

            return response
        } catch {
            let urlDescription = String(describing: url)
            let errorDescription = String(describing: error)
            logger.error(
                """
                SwiftNIOHTTPClient(\(httpMethod) \(urlDescription)) \
                failed with error: \(errorDescription)
                """
            )
            throw error
        }
    }

    /// Create an AsyncHTTPClient request from a Smithy HTTPRequest
    private func makeNIORequest(
        from request: SmithyHTTPAPI.HTTPRequest
    ) async throws -> AsyncHTTPClient.HTTPClientRequest {
        var components = URLComponents()
        components.scheme = config.protocolType?.rawValue ??
            request.destination.scheme.rawValue
        components.host = request.endpoint.uri.host
        components.port = port(for: request)
        components.percentEncodedPath = request.destination.path
        if let queryItems = request.queryItems, !queryItems.isEmpty {
            components.percentEncodedQueryItems = queryItems.map {
                URLQueryItem(name: $0.name, value: $0.value)
            }
        }
        guard let url = components.url else {
            throw SwiftNIOHTTPClientError.incompleteHTTPRequest
        }

        let method = NIOHTTP1.HTTPMethod(rawValue: request.method.rawValue)
        var nioRequest = AsyncHTTPClient.HTTPClientRequest(url: url.absoluteString)
        nioRequest.method = method

        // request headers will replace default if the same value is present in both
        for header in config.defaultHeaders.headers + request.headers.headers {
            for value in header.value {
                nioRequest.headers.replaceOrAdd(name: header.name, value: value)
            }
        }

        nioRequest.body = try await SwiftNIOHTTPClientStreamBridge.convertRequestBody(
            from: request.body,
            allocator: allocator
        )

        return nioRequest
    }

    private func port(for request: SmithyHTTPAPI.HTTPRequest) -> Int? {
        switch (request.destination.scheme, request.destination.port) {
        case (.https, 443), (.http, 80):
            return nil
        default:
            return request.destination.port.map { Int($0) }
        }
    }

    private func logBodyDescription(_ body: ByteStream) {
        switch body {
        case .stream(let stream):
            let lengthString: String
            if let length = stream.length {
                lengthString = "\(length) bytes"
            } else {
                lengthString = "unknown length"
            }
            logger.debug("body is Stream (\(lengthString))")
        case .data(let data):
            if let data {
                logger.debug("body is Data (\(data.count) bytes)")
            } else {
                logger.debug("body is empty")
            }
        case .noStream:
            logger.debug("body is empty")
        }
    }
}
