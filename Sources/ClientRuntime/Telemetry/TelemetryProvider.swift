//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A Telemetry Provider provides the SDK-level Telemetry configuration values.
public protocol TelemetryProvider: Sendable {
    /// The configured Telemetry Context Manager.
    var contextManager: any TelemetryContextManager { get }
    /// The configured Logger Provider.
    var loggerProvider: any LoggerProvider { get }
    /// The configured Meter Provider.
    var meterProvider: any MeterProvider { get }
    /// The configured Tracer Provider.
    var tracerProvider: any TracerProvider { get }
}
