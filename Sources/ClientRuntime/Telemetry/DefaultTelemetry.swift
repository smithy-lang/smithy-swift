//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Namespace for the Default SDK Telemetry implementations.
public enum DefaultTelemetry {
    /// The Default SDK Telemetry Provider Implementation.
    ///
    /// - contextManager: no-op
    /// - loggerProvider: provides SwiftLoggers
    /// - meterProvider: no-op
    /// - tracerProvider: no-op
    public static let Provider: TelemetryProvider = _DefaultTelemetryProvider()

    fileprivate class _DefaultTelemetryProvider: TelemetryProvider {
        let contextManager: TelemetryContextManager = DefaultTelemetryContextManager
        let loggerProvider: LoggerProvider = DefaultLoggerProvider
        let meterProvider: MeterProvider = DefaultMeterProvider
        let tracerProvider: TracerProvider = DefaultTracerProvider
    }
}

// Context
extension DefaultTelemetry {
    fileprivate static let DefaultTelemetryContextManager: TelemetryContextManager = NoOpTelemetryContextManager()
    fileprivate static let DefaultTelemetryContext: TelemetryContext = NoOpTelemetryContext()
    fileprivate static let DefaultTelemetryScope: TelemetryScope = NoOpTelemetryScope()

    fileprivate class NoOpTelemetryContextManager: TelemetryContextManager {
        func current() -> TelemetryContext { DefaultTelemetryContext }
    }
    fileprivate class NoOpTelemetryContext: TelemetryContext {
        func makeCurrent() -> TelemetryScope { DefaultTelemetryScope }
    }
    fileprivate class NoOpTelemetryScope: TelemetryScope {
        func end() {}
    }
}

// Logging
extension DefaultTelemetry {
    fileprivate static let DefaultLoggerProvider: LoggerProvider = _DefaultLoggerProvider()

    fileprivate class _DefaultLoggerProvider: LoggerProvider {
        func getLogger(name: String) -> LogAgent { SwiftLogger(label: name) }
    }
}

// Metrics
extension DefaultTelemetry {
    fileprivate static let DefaultMeterProvider: MeterProvider = NoOpMeterProvider()
    fileprivate static let DefaultMeter: Meter = NoOpMeter()
    fileprivate static let DefaultAsyncMeasurementHandle: AsyncMeasurementHandle = NoOpAsyncMeasurementHandle()
    fileprivate static let DefaultUpDownCounter: UpDownCounter = NoOpUpDownCounter()
    fileprivate static let DefaultMonotonicCounter: MonotonicCounter = NoOpMonotonicCounter()
    fileprivate static let DefaultHistogram: Histogram = NoOpHistogram()

    fileprivate class NoOpMeterProvider: MeterProvider {
        func getMeter(scope: String, attributes: Attributes?) -> Meter { DefaultMeter }
    }
    fileprivate class NoOpMeter: Meter {
        func createGauge(
            name: String,
            callback: @escaping (any DoubleAsyncMeasurement) -> Void,
            units: String?,
            description: String?
        ) -> AsyncMeasurementHandle {
            DefaultAsyncMeasurementHandle
        }
        func createUpDownCounter(
            name: String,
            units: String?,
            description: String?
        ) -> UpDownCounter {
            DefaultUpDownCounter
        }
        func createAsyncUpDownCounter(
            name: String,
            callback: @escaping (any LongAsyncMeasurement) -> Void,
            units: String?,
            description: String?
        ) -> AsyncMeasurementHandle {
            DefaultAsyncMeasurementHandle
        }
        func createCounter(
            name: String,
            units: String?,
            description: String?
        ) -> MonotonicCounter {
            DefaultMonotonicCounter
        }
        func createAsyncMonotonicCounter(
            name: String,
            callback: @escaping (any LongAsyncMeasurement) -> Void,
            units: String?,
            description: String?
        ) -> AsyncMeasurementHandle {
            DefaultAsyncMeasurementHandle
        }
        func createHistogram(
            name: String,
            units: String?,
            description: String?
        ) -> Histogram {
            DefaultHistogram
        }
    }
    fileprivate class NoOpAsyncMeasurementHandle: AsyncMeasurementHandle {
        func stop() {}
    }
    fileprivate class NoOpUpDownCounter: UpDownCounter {
        func add(value: Int64, attributes: Attributes?, context: TelemetryContext?) {}
    }
    fileprivate class NoOpMonotonicCounter: MonotonicCounter {
        func add(value: Int64, attributes: Attributes?, context: TelemetryContext?) {}
    }
    fileprivate class NoOpHistogram: Histogram {
        func record(value: Double, attributes: Attributes?, context: TelemetryContext?) {}
    }
}

// Trace
extension DefaultTelemetry {
    fileprivate static let DefaultTracerProvider: TracerProvider = NoOpTracerProvider()
    fileprivate static let DefaultTracer: Tracer = NoOpTracer()
    fileprivate static let DefaultTraceSpan: TraceSpan = NoOpTraceSpan()

    fileprivate class NoOpTracerProvider: TracerProvider {
        func getTracer(scope: String, attributes: Attributes?) -> Tracer { DefaultTracer }
    }
    fileprivate class NoOpTracer: Tracer {
        func createSpan(
            name: String,
            initialAttributes: Attributes?,
            spanKind: SpanKind,
            parentContext: TelemetryContext?
        ) -> TraceSpan {
            DefaultTraceSpan
        }
    }
    fileprivate class NoOpTraceSpan: TraceSpan {
        let name: String = ""
        func emitEvent(name: String, attributes: Attributes?) {}
        func setAttribute<T>(key: AttributeKey<T>, value: T) {}
        func setStatus(status: TraceSpanStatus) {}
        func end() {}
    }
}
