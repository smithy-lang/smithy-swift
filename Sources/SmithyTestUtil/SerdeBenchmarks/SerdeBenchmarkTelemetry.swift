//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyTelemetryAPI

public final class SerdeBenchmarkTelemetryProvider: TelemetryProvider {
    public let requestHistogram: SerdeBenchmarkHistogram
    public let responseHistogram: SerdeBenchmarkHistogram
    public let contextManager: any SmithyTelemetryAPI.TelemetryContextManager
    public let loggerProvider: any SmithyTelemetryAPI.LoggerProvider
    public let meterProvider: any SmithyTelemetryAPI.MeterProvider
    public let tracerProvider: any SmithyTelemetryAPI.TracerProvider

    public init() {
        self.requestHistogram = SerdeBenchmarkHistogram()
        self.responseHistogram = SerdeBenchmarkHistogram()
        self.contextManager = NoOpTelemetryContextManager()
        self.loggerProvider = DefaultLoggerProvider()
        self.meterProvider = SerdeBenchmarkMeterProvider(
            requestHistogram: requestHistogram,
            responseHistogram: responseHistogram
        )
        self.tracerProvider = NoOpTracerProvider()
    }
}

final class SerdeBenchmarkMeterProvider: MeterProvider {
    let requestHistogram: any Histogram
    let responseHistogram: any Histogram

    init(requestHistogram: any Histogram, responseHistogram: any Histogram) {
        self.requestHistogram = requestHistogram
        self.responseHistogram = responseHistogram
    }

    func getMeter(scope: String, attributes: Smithy.Attributes?) -> any SmithyTelemetryAPI.Meter {
        return SerdeBenchmarkMeter(requestHistogram: requestHistogram, responseHistogram: responseHistogram)
    }
}

final class SerdeBenchmarkMeter: Meter {
    let requestHistogram: any Histogram
    let responseHistogram: any Histogram

    init(requestHistogram: any Histogram, responseHistogram: any Histogram) {
        self.requestHistogram = requestHistogram
        self.responseHistogram = responseHistogram
    }

    func createGauge(name: String, callback: @escaping (any SmithyTelemetryAPI.DoubleAsyncMeasurement) -> Void, units: String?, description: String?) -> any SmithyTelemetryAPI.AsyncMeasurementHandle {
        NoOpAsyncMeasurementHandle()
    }

    func createUpDownCounter(name: String, units: String?, description: String?) -> any SmithyTelemetryAPI.UpDownCounter {
        NoOpUpDownCounter()
    }

    func createAsyncUpDownCounter(name: String, callback: @escaping (any SmithyTelemetryAPI.LongAsyncMeasurement) -> Void, units: String?, description: String?) -> any SmithyTelemetryAPI.AsyncMeasurementHandle {
        NoOpAsyncMeasurementHandle()
    }

    func createCounter(name: String, units: String?, description: String?) -> any SmithyTelemetryAPI.MonotonicCounter {
        NoOpMonotonicCounter()
    }

    func createAsyncMonotonicCounter(name: String, callback: @escaping (any SmithyTelemetryAPI.LongAsyncMeasurement) -> Void, units: String?, description: String?) -> any SmithyTelemetryAPI.AsyncMeasurementHandle {
        NoOpAsyncMeasurementHandle()
    }

    func createHistogram(name: String, units: String?, description: String?) -> any SmithyTelemetryAPI.Histogram {
        if name == "smithy.client.serialization_duration" {
            requestHistogram
        } else if name == "smithy.client.deserialization_duration" {
            responseHistogram
        } else {
            NoOpHistogram()
        }
    }
}

public final class SerdeBenchmarkHistogram: @unchecked Sendable, Histogram {
    public var value = -1.0
    public var attributes = Attributes()

    public init() {}

    public func record(value: Double, attributes: Smithy.Attributes?, context: (any SmithyTelemetryAPI.TelemetryContext)?) {
        self.value = value
        self.attributes = attributes ?? Attributes()
    }
}

fileprivate final class NoOpTelemetryContextManager: TelemetryContextManager {
    func current() -> TelemetryContext { NoOpTelemetryContext() }
}

fileprivate final class NoOpTelemetryContext: TelemetryContext {
    func makeCurrent() -> TelemetryScope { NoOpTelemetryScope() }
}

fileprivate final class NoOpTelemetryScope: TelemetryScope {
    func end() {}
}

fileprivate final class DefaultLoggerProvider: LoggerProvider {
    func getLogger(name: String) -> LogAgent { SwiftLogger(label: name) }
}

fileprivate final class NoOpTracerProvider: TracerProvider {
    func getTracer(scope: String) -> Tracer { NoOpTracer() }
}

fileprivate final class NoOpAsyncMeasurementHandle: AsyncMeasurementHandle {
    func stop() {}
}

fileprivate final class NoOpUpDownCounter: UpDownCounter {
    func add(value: Int, attributes: Attributes?, context: TelemetryContext?) {}
}

fileprivate final class NoOpMonotonicCounter: MonotonicCounter {
    func add(value: Int, attributes: Attributes?, context: TelemetryContext?) {}
}

fileprivate final class NoOpHistogram: Histogram {
    func record(value: Double, attributes: Attributes?, context: TelemetryContext?) {}
}

fileprivate final class NoOpTracer: Tracer {
    func createSpan(
        name: String,
        initialAttributes: Attributes?,
        spanKind: SpanKind,
        parentContext: TelemetryContext?
    ) -> TraceSpan {
        NoOpTraceSpan()
    }
}

fileprivate final class NoOpTraceSpan: TraceSpan {
    let name: String = ""
    func emitEvent(name: String, attributes: Attributes?) {}
    func setAttribute<T>(key: AttributeKey<T>, value: T) {}
    func setStatus(status: TraceSpanStatus) {}
    func end() {}
}
