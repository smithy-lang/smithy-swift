//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if AWS_SWIFT_SDK_ENABLE_OPENTELEMETRY && (os(macOS) || os(iOS) || os(watchOS) || os(tvOS))

// OpenTelemetryApi specific imports
@preconcurrency import protocol OpenTelemetryApi.Tracer
@preconcurrency import protocol OpenTelemetryApi.Span
@preconcurrency import enum OpenTelemetryApi.SpanKind
@preconcurrency import enum OpenTelemetryApi.Status
@preconcurrency import enum OpenTelemetryApi.AttributeValue

// OpenTelemetrySdk specific imports
@preconcurrency import class OpenTelemetrySdk.TracerProviderSdk
@preconcurrency import class OpenTelemetrySdk.TracerProviderBuilder
@preconcurrency import struct OpenTelemetrySdk.SimpleSpanProcessor
@preconcurrency import protocol OpenTelemetrySdk.SpanExporter
@preconcurrency import struct OpenTelemetrySdk.Resource

// Smithy specific imports
import struct Smithy.AttributeKey
import struct Smithy.Attributes

public typealias OpenTelemetryTracer = OpenTelemetryApi.Tracer
public typealias OpenTelemetrySpanKind = OpenTelemetryApi.SpanKind
public typealias OpenTelemetrySpan = OpenTelemetryApi.Span
public typealias OpenTelemetryStatus = OpenTelemetryApi.Status

// Trace
public final class OTelTracerProvider: TracerProvider {
    private let sdkTracerProvider: TracerProviderSdk

    public init(spanExporter: SpanExporter) {
        self.sdkTracerProvider = TracerProviderBuilder()
            .add(spanProcessor: SimpleSpanProcessor(spanExporter: spanExporter))
            .with(resource: Resource())
            .build()
    }

    public func getTracer(scope: String) -> any Tracer {
        let tracer = self.sdkTracerProvider.get(instrumentationName: scope)
        return OTelTracerImpl(otelTracer: tracer)
    }
}

public final class OTelTracerImpl: Tracer {
    private let otelTracer: OpenTelemetryTracer

    public init(otelTracer: OpenTelemetryTracer) {
        self.otelTracer = otelTracer
    }

    public func createSpan(
        name: String,
        initialAttributes: Attributes?, spanKind: SpanKind, parentContext: (any TelemetryContext)?
    ) -> any TraceSpan {
        let spanBuilder = self.otelTracer
            .spanBuilder(spanName: name)
            .setSpanKind(spanKind: spanKind.toOTelSpanKind())

        initialAttributes?.getKeys().forEach { key in
            spanBuilder.setAttribute(
                key: key,
                value: (initialAttributes?.get(key: AttributeKey<String>(name: key)))!
            )
        }

        return OTelTraceSpanImpl(name: name, otelSpan: spanBuilder.startSpan())
    }
}

private final class OTelTraceSpanImpl: TraceSpan {
    let name: String
    private let otelSpan: OpenTelemetrySpan

    public init(name: String, otelSpan: OpenTelemetrySpan) {
        self.name = name
        self.otelSpan = otelSpan
    }

    func emitEvent(name: String, attributes: Attributes?) {
        if let attributes = attributes, !(attributes.size == 0) {
            self.otelSpan.addEvent(name: name, attributes: attributes.toOtelAttributes())
        } else {
            self.otelSpan.addEvent(name: name)
        }
    }

    func setAttribute<T>(key: AttributeKey<T>, value: T) {
        self.otelSpan.setAttribute(key: key.getName(), value: AttributeValue.init(value))
    }

    func setStatus(status: TraceSpanStatus) {
        self.otelSpan.status = status.toOTelStatus()
    }

    func end() {
        self.otelSpan.end()
    }
}

extension SpanKind {
    func toOTelSpanKind() -> OpenTelemetrySpanKind {
        switch self {
        case .client:
            return .client
        case .consumer:
            return .consumer
        case .internal:
            return .internal
        case .producer:
            return .producer
        case .server:
            return .server
        }
    }
}

extension TraceSpanStatus {
    func toOTelStatus() -> OpenTelemetryStatus {
        switch self {
        case .error:
            return .error(description: "An error occured!") // status doesn't have error description
        case .ok:
            return .ok
        case .unset:
            return .unset
        }
    }
}

#endif