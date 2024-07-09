//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import struct Smithy.Attributes
import struct Smithy.AttributeKey
import enum SmithyHTTPAPI.SmithyHTTPAPIKeys

/// Container for Orchestrator telemetry, including configurable attributes and names.
///
/// Note: This is intended to be used within generated code, not directly.
public class OrchestratorTelemetry {
    internal let contextManager: any TelemetryContextManager
    internal let tracerProvider: any TracerProvider

    internal let metricsAttributes: Attributes
    internal let tracerScope: String
    internal let tracerAttributes: Attributes?
    internal let spanName: String
    internal let spanAttributes: Attributes?

    internal let rpcAttempts: any MonotonicCounter
    internal let rpcErrors: any MonotonicCounter
    internal let rpcCallDuration: any Histogram
    internal let serializationDuration: any Histogram
    internal let rpcAttemptDuration: any Histogram
    internal let resolveIdentityDuration: any Histogram
    internal let resolveEndpointDuration: any Histogram
    internal let signingDuration: any Histogram
    internal let deserializationDuration: any Histogram

    public init(
        telemetryProvider: any TelemetryProvider,
        metricsAttributes: Attributes,
        meterScope: String = "unknown",
        meterAttributes: Attributes? = nil,
        tracerScope: String? = nil,
        tracerAttributes: Attributes? = nil,
        spanName: String? = nil,
        spanAttributes: Attributes? = nil
    ) {
        self.contextManager = telemetryProvider.contextManager
        self.tracerProvider = telemetryProvider.tracerProvider

        self.metricsAttributes = metricsAttributes
        if let tracerScope = tracerScope {
            self.tracerScope = tracerScope
        } else {
            self.tracerScope = createTracerScope(attributes: metricsAttributes)
        }
        self.tracerAttributes = tracerAttributes
        if let spanName = spanName {
            self.spanName = spanName
        } else {
            self.spanName = createSpanName(attributes: metricsAttributes)
        }
        self.spanAttributes = spanAttributes

        let meter = telemetryProvider.meterProvider.getMeter(scope: meterScope, attributes: meterAttributes)
        self.rpcAttempts = meter.createCounter(
            name: "smithy.client.attempts",
            units: "{attempt}",
            description: "The number of attempts for an operation")
        self.rpcErrors = meter.createCounter(
            name: "smithy.client.errors",
            units: "{error}",
            description: "The number of errors for an operation")
        self.rpcCallDuration = meter.createHistogram(
            name: "smithy.client.duration",
            units: "s",
            description: "Overall call duration including retries")
        self.serializationDuration = meter.createHistogram(
            name: "smithy.client.serialization_duration",
            units: "s",
            description: "The time it takes to serialize a request message body")
        self.rpcAttemptDuration = meter.createHistogram(
            name: "smithy.client.attempt_duration",
            units: "s",
            description: "The time it takes to connect to the service, send the request, "
                       + "and receive the HTTP status code and headers from the response for an operation")
        self.resolveIdentityDuration = meter.createHistogram(
            name: "smithy.client.auth.resolve_identity_duration",
            units: "s",
            description: "The time it takes to resolve an identity for signing a request")
        self.resolveEndpointDuration = meter.createHistogram(
            name: "smithy.client.resolve_endpoint_duration",
            units: "s",
            description: "The time it takes to resolve an endpoint for a request")
        self.signingDuration = meter.createHistogram(
            name: "smithy.client.auth.signing_duration",
            units: "s",
            description: "The time it takes to sign a request")
        self.deserializationDuration = meter.createHistogram(
            name: "smithy.client.deserialization_duration",
            units: "s",
            description: "The time it takes to deserialize a response message body")
    }
}

public enum OrchestratorMetricsAttributesKeys {
    public static let service = AttributeKey<String>(name: "rpc.service")
    public static let method = AttributeKey<String>(name: "rpc.method")
}

private func createTracerScope(attributes: Attributes) -> String {
    return attributes.get(key: OrchestratorMetricsAttributesKeys.service)!
}

private func createSpanName(attributes: Attributes) -> String {
    let service = attributes.get(key: OrchestratorMetricsAttributesKeys.service)!
    let method = attributes.get(key: OrchestratorMetricsAttributesKeys.method)!
    return "\(service).\(method)"
}
