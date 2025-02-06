//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public class TelemetryPlugin<Config: DefaultClientConfiguration>: Plugin {

    private let telemetryProvider: TelemetryProvider

    public init(telemetryProvider: TelemetryProvider) {
        self.telemetryProvider = telemetryProvider
    }

    public init(
        contextManager: TelemetryContextManager? = DefaultTelemetry.defaultContextManager,
        loggerProvider: LoggerProvider? = DefaultTelemetry.defaultLoggerProvider,
        meterProvider: MeterProvider? = DefaultTelemetry.defaultMeterProvider,
        tracerProvider: TracerProvider? = DefaultTelemetry.defaultTracerProvider
    ) {
        self.telemetryProvider = BasicTelemetryProvider(
            contextManager: contextManager!,
            loggerProvider: loggerProvider!,
            meterProvider: meterProvider!,
            tracerProvider: tracerProvider!
        )
    }

    public func configureClient(clientConfiguration: Config) -> Config {
        var copy = clientConfiguration
        copy.telemetryProvider = self.telemetryProvider
        return copy
    }
}

private final class BasicTelemetryProvider: TelemetryProvider {
    let contextManager: TelemetryContextManager
    let loggerProvider: LoggerProvider
    let meterProvider: MeterProvider
    let tracerProvider: TracerProvider

    fileprivate init(
        contextManager: TelemetryContextManager,
        loggerProvider: LoggerProvider,
        meterProvider: MeterProvider,
        tracerProvider: TracerProvider
    ) {
        self.contextManager = contextManager
        self.loggerProvider = loggerProvider
        self.meterProvider = meterProvider
        self.tracerProvider = tracerProvider
    }
}
