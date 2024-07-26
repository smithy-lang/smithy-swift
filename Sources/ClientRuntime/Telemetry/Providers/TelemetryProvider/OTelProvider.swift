//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import InMemoryExporter
import OpenTelemetryApi
import OpenTelemetrySdk
import Smithy

/// Namespace for the SDK Telemetry implementation.
public enum TelemetryProviderOTel {
    /// The SDK TelemetryProviderOTel Implementation.
    ///
    /// - contextManager: no-op
    /// - loggerProvider: provides SwiftLoggers
    /// - meterProvider: no-op
    /// - tracerProvider: no-op
    public static let provider: TelemetryProvider = OpenTelemetryProvider(spanExporter: InMemoryExporter())

    public final class OpenTelemetryProvider: TelemetryProvider {
        public let contextManager: TelemetryContextManager
        public let loggerProvider: LoggerProvider
        public let meterProvider: MeterProvider
        public let tracerProvider: TracerProvider

        public init(spanExporter: SpanExporter) {
            self.contextManager = defaultContextManager
            self.loggerProvider = defaultLoggerProvider
            self.meterProvider = OTelMeterProvider()
            self.tracerProvider = OTelTracerProvider(spanExporter: spanExporter)
        }
    }
}

// Logging
extension TelemetryProviderOTel {
    public static let defaultLoggerProvider: LoggerProvider = _DefaultLoggerProvider()

    fileprivate final class _DefaultLoggerProvider: LoggerProvider {
        func getLogger(name: String) -> LogAgent { SwiftLogger(label: name) }
    }
}
