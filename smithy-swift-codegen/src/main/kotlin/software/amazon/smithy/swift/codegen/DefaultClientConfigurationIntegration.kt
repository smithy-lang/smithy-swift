package software.amazon.smithy.swift.codegen

import software.amazon.smithy.swift.codegen.config.ClientConfiguration
import software.amazon.smithy.swift.codegen.config.DefaultClientConfiguration
import software.amazon.smithy.swift.codegen.config.DefaultHttpClientConfiguration
import software.amazon.smithy.swift.codegen.integration.Plugin
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.integration.plugins.DefaultPlugins

class DefaultClientConfigurationIntegration : SwiftIntegration {
    override fun plugins(): List<Plugin> {
        return DefaultPlugins.values().toList()
    }

    override fun clientConfigurations(): List<ClientConfiguration> {
        return listOf(DefaultClientConfiguration(), DefaultHttpClientConfiguration())
    }
}
