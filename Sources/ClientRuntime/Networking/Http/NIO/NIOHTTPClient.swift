//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AsyncHTTPClient
import NIOCore
import NIOPosix
import NIOSSL
import struct Smithy.Attributes
import struct Smithy.SwiftLogger
import protocol Smithy.LogAgent
import struct SmithyHTTPAPI.Headers
import class SmithyHTTPAPI.HTTPResponse
import class SmithyHTTPAPI.HTTPRequest
import enum SmithyHTTPAPI.HTTPStatusCode
import protocol Smithy.ReadableStream
import enum Smithy.ByteStream
import class SmithyStreams.BufferedStream
import struct Foundation.Date
import AwsCommonRuntimeKit

/// AsyncHTTPClient-based HTTP client implementation that conforms to SmithyHTTPAPI.HTTPClient
/// This implementation is thread-safe and supports concurrent request execution.
public final class NIOHTTPClient: SmithyHTTPAPI.HTTPClient {
    public static let noOpNIOHTTPClientTelemetry = HttpTelemetry(
        httpScope: "NIOHTTPClient",
        telemetryProvider: DefaultTelemetry.provider
    )

    private let client: AsyncHTTPClient.HTTPClient
    private let config: HttpClientConfiguration
    private let tlsConfiguration: NIOHTTPClientTLSOptions?
    private let allocator: ByteBufferAllocator

    /// HTTP Client Telemetry
    private let telemetry: HttpTelemetry

    /// Logger for HTTP-related events.
    private var logger: LogAgent

    /// Creates a new `NIOHTTPClient`.
    ///
    /// The client is created with its own internal `AsyncHTTPClient`, which is configured with system defaults.
    /// - Parameters:
    ///   - httpClientConfiguration: The configuration to use for the client's `AsyncHTTPClient` setup.
    public init(
        httpClientConfiguration: HttpClientConfiguration
    ) throws {
        self.config = httpClientConfiguration
        self.telemetry = httpClientConfiguration.telemetry ?? NIOHTTPClient.noOpNIOHTTPClientTelemetry
        self.logger = self.telemetry.loggerProvider.getLogger(name: "NIOHTTPClient")
        self.tlsConfiguration = httpClientConfiguration.tlsConfiguration as? NIOHTTPClientTLSOptions
        self.allocator = ByteBufferAllocator()

        var clientConfig = AsyncHTTPClient.HTTPClient.Configuration()

        // Configure TLS if options are provided
        if let tlsOptions = tlsConfiguration {
            clientConfig.tlsConfiguration = try tlsOptions.makeNIOSSLConfiguration()
        }

        self.client = AsyncHTTPClient.HTTPClient(configuration: clientConfig)
    }

    public func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> SmithyHTTPAPI.HTTPResponse {
        let telemetryContext = telemetry.contextManager.current()
        let tracer = telemetry.tracerProvider.getTracer(
            scope: telemetry.tracerScope
        )
        do {
            // START - smithy.client.http.requests.queued_duration
            let queuedStart = Date().timeIntervalSinceReferenceDate
            let span = tracer.createSpan(
                name: telemetry.spanName,
                initialAttributes: telemetry.spanAttributes,
                spanKind: SpanKind.internal,
                parentContext: telemetryContext)
            defer {
                span.end()
            }

            // START - smithy.client.http.connections.acquire_duration
            let acquireConnectionStart = Date().timeIntervalSinceReferenceDate

            // TODO: Convert Smithy HTTPRequest to AsyncHTTPClient HTTPClientRequest

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
                context: telemetryContext)
            // END - smithy.client.http.requests.queued_duration

            // TODO: Update connection and request usage metrics based on AsyncHTTPClient configuration
            telemetry.updateHTTPMetricsUsage { httpMetricsUsage in
                // TICK - smithy.client.http.connections.limit
                httpMetricsUsage.connectionsLimit = 0 // TODO: Get from AsyncHTTPClient configuration

                // TICK - smithy.client.http.connections.usage
                httpMetricsUsage.acquiredConnections = 0 // TODO: Get from AsyncHTTPClient
                httpMetricsUsage.idleConnections = 0 // TODO: Get from AsyncHTTPClient

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
                    context: telemetryContext)
            }

            // TODO: Execute the HTTP request using AsyncHTTPClient

            // TODO: Log body description

            // TODO: Handle response
            // TODO: Record bytes sent during request body streaming with server address attributes
            // TODO: Record bytes received during response streaming with server address attributes

            // TODO: Convert NIO response to Smithy HTTPResponse

            return HTTPResponse() // TODO: Return actual response
        } catch {
            // TODO: Handle catch
        }
    }
}
