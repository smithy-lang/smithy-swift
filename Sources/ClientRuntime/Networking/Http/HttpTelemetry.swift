/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import class Foundation.NSRecursiveLock
import struct Smithy.AttributeKey
import struct Smithy.Attributes
import protocol SmithyHTTPAPI.HTTPClient

/// Container for HTTPClient telemetry, including configurable attributes and names.
///
/// Note: This is intended to be used within generated code, not directly.
public class HttpTelemetry: @unchecked Sendable {
    private static var idleConnectionAttributes: Attributes {
        var attributes = Attributes()
        attributes.set(key: HttpMetricsAttributesKeys.state, value: ConnectionState.idle)
        return attributes
    }
    private static var acquiredConnectionAttributes: Attributes {
        var attributes = Attributes()
        attributes.set(key: HttpMetricsAttributesKeys.state, value: ConnectionState.acquired)
        return attributes
    }
    private static var inflightRequestsAttributes: Attributes {
        var attributes = Attributes()
        attributes.set(key: HttpMetricsAttributesKeys.state, value: RequestState.inflight)
        return attributes
    }
    private static var queuedRequestsAttributes: Attributes {
        var attributes = Attributes()
        attributes.set(key: HttpMetricsAttributesKeys.state, value: RequestState.queued)
        return attributes
    }

    internal let contextManager: any TelemetryContextManager
    internal let tracerProvider: any TracerProvider
    internal let loggerProvider: any LoggerProvider

    internal let tracerScope: String
    internal let spanName: String

    internal let connectionsAcquireDuration: any Histogram
    private let connectionsLimit: any AsyncMeasurementHandle
    private let connectionsUsage: any AsyncMeasurementHandle
    internal let connectionsUptime: any Histogram
    private let requestsUsage: any AsyncMeasurementHandle
    internal let requestsQueuedDuration: any Histogram
    internal let bytesSent: any MonotonicCounter
    internal let bytesReceived: any MonotonicCounter

    // Lock to enforce exclusive access to non-Sendable properties
    private let lock = NSRecursiveLock()

    // The properties _tracerAttributes, _spanAttributes, and _httpMetricsUsage
    // are not Sendable & must be protected by lock.
    private let _tracerAttributes: Attributes?

    var tracerAttributes: Attributes? {
        lock.lock()
        defer { lock.unlock() }
        return _tracerAttributes
    }

    private let _spanAttributes: Attributes?

    var spanAttributes: Attributes? {
        lock.lock()
        defer { lock.unlock() }
        return _spanAttributes
    }

    private var _httpMetricsUsage: HttpMetricsUsage

    var httpMetricsUsage: HttpMetricsUsage {
        lock.lock()
        defer { lock.unlock() }
        return _httpMetricsUsage
    }

    func updateHTTPMetricsUsage(_ block: (inout HttpMetricsUsage) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        block(&_httpMetricsUsage)
    }

    public init(
        httpScope: String,
        telemetryProvider: any TelemetryProvider = DefaultTelemetry.provider,
        meterScope: String? = nil,
        meterAttributes: Attributes? = nil,
        tracerScope: String? = nil,
        tracerAttributes: Attributes? = nil,
        spanName: String? = nil,
        spanAttributes: Attributes? = nil
    ) {
        self.contextManager = telemetryProvider.contextManager
        self.tracerProvider = telemetryProvider.tracerProvider
        self.loggerProvider = telemetryProvider.loggerProvider
        let meterScope: String = meterScope != nil ? meterScope! : httpScope
        self.tracerScope = tracerScope != nil ? tracerScope! : httpScope
        self._tracerAttributes = tracerAttributes
        self.spanName = spanName != nil ? spanName! : "HTTP"
        self._spanAttributes = spanAttributes
        let httpMetricsUsage = HttpMetricsUsage()
        self._httpMetricsUsage = httpMetricsUsage

        let meter = telemetryProvider.meterProvider.getMeter(scope: meterScope, attributes: meterAttributes)
        self.connectionsAcquireDuration = meter.createHistogram(
            name: "smithy.client.http.connections.acquire_duration",
            units: "s",
            description: "The time it takes a request to acquire a connection")
        self.connectionsLimit = meter.createAsyncUpDownCounter(
            name: "smithy.client.http.connections.limit",
            callback: { handle in
                handle.record(
                    value: httpMetricsUsage.connectionsLimit,
                    attributes: Attributes(),
                    context: telemetryProvider.contextManager.current()
                )
            },
            units: "{connection}",
            description: "The maximum open connections allowed/configured for the HTTP client")
        self.connectionsUsage = meter.createAsyncUpDownCounter(
            name: "smithy.client.http.connections.usage",
            callback: { handle in
                handle.record(
                    value: httpMetricsUsage.idleConnections,
                    attributes: HttpTelemetry.idleConnectionAttributes,
                    context: telemetryProvider.contextManager.current()
                )
                handle.record(
                    value: httpMetricsUsage.acquiredConnections,
                    attributes: HttpTelemetry.acquiredConnectionAttributes,
                    context: telemetryProvider.contextManager.current()
                )
            },
            units: "{connection}",
            description: "Current state of connections pool")
        self.connectionsUptime = meter.createHistogram(
            name: "smithy.client.http.connections.uptime",
            units: "s",
            description: "The amount of time a connection has been open")
        self.requestsUsage = meter.createAsyncUpDownCounter(
            name: "smithy.client.http.requests.usage",
            callback: { handle in
                handle.record(
                    value: httpMetricsUsage.idleConnections,
                    attributes: HttpTelemetry.idleConnectionAttributes,
                    context: telemetryProvider.contextManager.current()
                )
                handle.record(
                    value: httpMetricsUsage.acquiredConnections,
                    attributes: HttpTelemetry.acquiredConnectionAttributes,
                    context: telemetryProvider.contextManager.current()
                )
            },
            units: "{request}",
            description: "The current state of HTTP client request concurrency")
        self.requestsQueuedDuration = meter.createHistogram(
            name: "smithy.client.http.requests.queued_duration",
            units: "s",
            description: "The amount of time a request spent queued waiting to be executed by the HTTP client")
        self.bytesSent = meter.createCounter(
            name: "smithy.client.http.bytes_sent",
            units: "By",
            description: "The total number of bytes sent by the HTTP client")
        self.bytesReceived = meter.createCounter(
            name: "smithy.client.http.bytes_received",
            units: "By",
            description: "The total number of bytes received by the HTTP client")
    }

    deinit {
        self.connectionsLimit.stop()
        self.connectionsUsage.stop()
        self.requestsUsage.stop()
    }
}

private enum ConnectionState {
    fileprivate static let idle = "idle"
    fileprivate static let acquired = "acquired"
}

private enum RequestState {
    fileprivate static let inflight = "inflight"
    fileprivate static let queued = "queued"
}

internal enum HttpMetricsAttributesKeys {
    fileprivate static let state = AttributeKey<String>(name: "state")
    internal static let serverAddress = AttributeKey<String>(name: "server.address")
}

internal struct HttpMetricsUsage {
    public var connectionsLimit: Int = 0
    public var idleConnections: Int = 0
    public var acquiredConnections: Int = 0
    public var inflightRequests: Int = 0
    public var queuedRequests: Int = 0
}
