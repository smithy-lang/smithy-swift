/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.config

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.toOptional
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyRetriesAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes

class DefaultClientConfiguration : ClientConfiguration {
    override val swiftProtocolName: Symbol = ClientRuntimeTypes.Core.DefaultClientConfiguration

    override fun getProperties(ctx: ProtocolGenerator.GenerationContext): Set<ConfigProperty> = setOf(
        ConfigProperty(
            "telemetryProvider",
            ClientRuntimeTypes.Core.TelemetryProvider,
            { it.format("\$N.provider", ClientRuntimeTypes.Core.DefaultTelemetry) },
        ),
        ConfigProperty(
            "retryStrategyOptions",
            SmithyRetriesAPITypes.RetryStrategyOptions,
            { it.format("\$N.defaultRetryStrategyOptions", ClientRuntimeTypes.Core.ClientConfigurationDefaults) },
        ),
        ConfigProperty(
            "clientLogMode",
            ClientRuntimeTypes.Core.ClientLogMode,
            { it.format("\$N.defaultClientLogMode", ClientRuntimeTypes.Core.ClientConfigurationDefaults) },
        ),
        ConfigProperty("endpoint", SwiftTypes.String.toOptional()),
        ConfigProperty(
            "idempotencyTokenGenerator",
            ClientRuntimeTypes.Core.IdempotencyTokenGenerator,
            { it.format("\$N.defaultIdempotencyTokenGenerator", ClientRuntimeTypes.Core.ClientConfigurationDefaults) },
        ),
    )
}
