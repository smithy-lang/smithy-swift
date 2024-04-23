/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.test.utils

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.config.ClientConfiguration
import software.amazon.smithy.swift.codegen.config.ClientConfiguration.Companion.runtimeSymbol
import software.amazon.smithy.swift.codegen.config.ConfigProperty
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.toOptional

class WeatherClientConfigurationIntegration : SwiftIntegration {

    override val protocolGenerators: List<ProtocolGenerator>
        get() {
            return listOf(TestProtocolGenerator())
        }

    override fun clientConfigurations(ctx: ProtocolGenerator.GenerationContext): List<ClientConfiguration> {
        return listOf(StageConfiguration())
    }
}

private class StageConfiguration : ClientConfiguration {
    override val swiftProtocolName: Symbol
        get() = runtimeSymbol("StageConfiguration", SwiftDependency.SMITHY_TEST_UTIL)

    override fun getProperties(ctx: ProtocolGenerator.GenerationContext): Set<ConfigProperty> {
        return setOf(ConfigProperty("stage", SwiftTypes.String.toOptional(), "\"prod\""))
    }
}
