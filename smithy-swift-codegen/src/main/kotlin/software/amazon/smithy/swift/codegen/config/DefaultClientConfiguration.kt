/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.config

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.config.ClientConfiguration.Companion.runtimeSymbol
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.toOptional
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyRetriesAPITypes

class DefaultClientConfiguration : ClientConfiguration {
    override val swiftProtocolName: Symbol
        get() = runtimeSymbol("DefaultClientConfiguration", SwiftDependency.CLIENT_RUNTIME)

    override fun getProperties(ctx: ProtocolGenerator.GenerationContext): Set<ConfigProperty> = setOf(
        ConfigProperty(
            "telemetryProvider",
            ClientRuntimeTypes.Core.TelemetryProvider,
            "ClientRuntime.DefaultTelemetry.provider"
        ),
        ConfigProperty(
            "retryStrategyOptions",
            SmithyRetriesAPITypes.RetryStrategyOptions,
            "ClientConfigurationDefaults.defaultRetryStrategyOptions"
        ),
        ConfigProperty(
            "clientLogMode",
            ClientRuntimeTypes.Core.ClientLogMode,
            "ClientConfigurationDefaults.defaultClientLogMode"
        ),
        ConfigProperty("endpoint", SwiftTypes.String.toOptional()),
        ConfigProperty(
            "idempotencyTokenGenerator",
            ClientRuntimeTypes.Core.IdempotencyTokenGenerator,
            "ClientConfigurationDefaults.defaultIdempotencyTokenGenerator"
        ),
    )
}
