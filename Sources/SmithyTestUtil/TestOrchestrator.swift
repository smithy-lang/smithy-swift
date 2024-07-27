//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import Smithy
import SmithyHTTPAPI

public struct TestOrchestrator {
    /// - Returns: An OrchestratorBuilder set up with defaults for selectAuthScheme and telemetry.
    public static func httpBuilder<Input, Output>() -> OrchestratorBuilder<Input, Output, HTTPRequest, HTTPResponse> {
        var metricsAttributes = Attributes()
        metricsAttributes.set(key: OrchestratorMetricsAttributesKeys.service, value: "Service")
        metricsAttributes.set(key: OrchestratorMetricsAttributesKeys.method, value: "Method")
        return OrchestratorBuilder()
            .selectAuthScheme(SelectNoAuthScheme())
            .telemetry(OrchestratorTelemetry(
                telemetryProvider: DefaultTelemetry.provider,
                metricsAttributes: metricsAttributes
            ))
    }
}