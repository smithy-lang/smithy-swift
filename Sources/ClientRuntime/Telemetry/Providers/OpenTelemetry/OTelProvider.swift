//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if !(os(Linux) || os(visionOS))
import OpenTelemetryApi
import OpenTelemetrySdk
import Smithy
import OpenTelemetryProtocolExporterHttp
import Foundation

/// Namespace for the SDK Telemetry implementation.
public enum OpenTelemetrySwift {
    /// The SDK TelemetryProviderOTel Implementation.
    ///
    /// - contextManager: no-op
    /// - loggerProvider: provides SwiftLoggers
    /// - meterProvider: no-op
    /// - tracerProvider: provides OTelTracerProvider with InMemoryExporter
    public static func provider(spanExporter: any SpanExporter) -> TelemetryProvider {
        return OpenTelemetrySwiftProvider(spanExporter: spanExporter)
    }

    public final class OpenTelemetrySwiftProvider: TelemetryProvider {
        public let contextManager: TelemetryContextManager
        public let loggerProvider: LoggerProvider
        public let meterProvider: MeterProvider
        public let tracerProvider: TracerProvider

        public init(spanExporter: SpanExporter) {
            self.contextManager = DefaultTelemetry.defaultContextManager
            self.loggerProvider = DefaultTelemetry.defaultLoggerProvider
            self.meterProvider = DefaultTelemetry.defaultMeterProvider
            self.tracerProvider = OTelTracerProvider(spanExporter: spanExporter)
        }
    }
}
#endif
