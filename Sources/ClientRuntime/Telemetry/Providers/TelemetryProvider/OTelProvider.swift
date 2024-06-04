//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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
    public static let provider: TelemetryProvider = OpenTelemetryProvider()

    fileprivate class OpenTelemetryProvider: TelemetryProvider {
        let contextManager: TelemetryContextManager = defaultContextManager
        let loggerProvider: LoggerProvider = defaultLoggerProvider
        let meterProvider: MeterProvider = OTelMeterProvider()
        let tracerProvider: TracerProvider = OTelTracerProvider()
    }
}

// Logging
extension TelemetryProviderOTel {
    public static let defaultLoggerProvider: LoggerProvider = _DefaultLoggerProvider()

    fileprivate class _DefaultLoggerProvider: LoggerProvider {
        func getLogger(name: String) -> LogAgent { SwiftLogger(label: name) }
    }
}
