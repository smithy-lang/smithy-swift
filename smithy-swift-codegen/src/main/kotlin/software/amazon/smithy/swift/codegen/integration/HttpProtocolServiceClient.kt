/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.config.ConfigProperty
import software.amazon.smithy.swift.codegen.integration.plugins.DefaultClientPlugin
import software.amazon.smithy.swift.codegen.model.renderSwiftType
import software.amazon.smithy.swift.codegen.model.toOptional
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase
import software.amazon.smithy.utils.CodeSection

open class HttpProtocolServiceClient(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val properties: List<ClientProperty>,
    private val serviceConfig: ServiceConfig
) {
    private val serviceName: String = ctx.settings.sdkId

    fun render(serviceSymbol: Symbol) {
        writer.openBlock("public class \$L: Client {", "}", serviceSymbol.name) {
            writer.write("public static let clientName = \$S", serviceSymbol.name)
            writer.write("let client: \$N", ClientRuntimeTypes.Http.SdkHttpClient)
            writer.write("let config: \$L", serviceConfig.typeName)
            writer.write("let serviceName = \$S", serviceName)
            writer.write("")
            properties.forEach { prop ->
                prop.addImportsAndDependencies(writer)
            }
            renderInitFunction(properties)
            writer.write("")
            renderConvenienceInitFunctions(serviceSymbol)
        }
        writer.write("")
        renderClientExtension(serviceSymbol)
        renderLogHandlerFactory(serviceSymbol)
        renderServiceSpecificPlugins()
    }

    open fun renderInitFunction(properties: List<ClientProperty>) {
        writer.openBlock("public required init(config: \$L) {", "}", serviceConfig.typeName) {
            writer.write(
                "client = \$N(engine: config.httpClientEngine, config: config.httpClientConfiguration)",
                ClientRuntimeTypes.Http.SdkHttpClient
            )

            properties.forEach { prop ->
                prop.renderInstantiation(writer)
                if (prop.needsConfigure) {
                    prop.renderConfiguration(writer)
                }
                prop.renderInitialization(writer, "config")
            }

            writer.write("self.config = config")
        }
        writer.write("")
    }

    open fun renderConvenienceInitFunctions(serviceSymbol: Symbol) {
        writer.openBlock("public convenience required init() throws {", "}") {
            writer.write("let config = try \$L()", serviceConfig.typeName)
            writer.write("self.init(config: config)")
        }
        writer.write("")
    }

    fun renderClientExtension(serviceSymbol: Symbol) {
        writer.openBlock("extension ${serviceSymbol.name} {", "}") {
            renderClientConfig(serviceSymbol)
            writer.write("")

            writer.openBlock("public static func builder() -> ClientBuilder<\$L> {", "}", serviceSymbol.name) {
                writer.openBlock("return ClientBuilder<\$L>(defaultPlugins: [", "])", serviceSymbol.name) {

                    val defaultPlugins: MutableList<Plugin> = mutableListOf(DefaultClientPlugin())

                    ctx.integrations
                        .flatMap { it.plugins(serviceConfig) }
                        .filter { it.isDefault }
                        .onEach { defaultPlugins.add(it) }

                    val pluginsIterator = defaultPlugins.iterator()

                    while (pluginsIterator.hasNext()) {
                        pluginsIterator.next().customInitialization(writer)
                        if (pluginsIterator.hasNext()) {
                            writer.write(",")
                        }
                    }

                    writer.unwrite(",\n").write("")
                }
            }
        }
        writer.write("")
    }

    open fun renderClientConfig(serviceSymbol: Symbol) {
        val clientConfigurationProtocols =
            ctx.integrations
                .flatMap { it.clientConfigurations(ctx) }
                .mapNotNull { it.swiftProtocolName?.name }
                .joinToString(" & ")

        writer.openBlock(
            "public class \$LConfiguration: \$L {", "}",
            serviceConfig.clientName.toUpperCamelCase(),
            clientConfigurationProtocols
        ) {
            val properties: List<ConfigProperty> = ctx.integrations
                .flatMap { it.clientConfigurations(ctx).flatMap { it.getProperties(ctx) } }
                .let { overrideConfigProperties(it) }
            properties.forEach { writer.addImport(it.type) }

            renderConfigClassVariables(serviceSymbol, properties)

            renderConfigInitializer(serviceSymbol, properties)

            renderSynchronousConfigInitializer(properties)

            renderAsynchronousConfigInitializer(properties)

            renderEmptyAsynchronousConfigInitializer(properties)

            renderCustomConfigInitializer(properties)

            renderPartitionID()
        }
        writer.write("")
    }

    open fun renderCustomConfigInitializer(properties: List<ConfigProperty>) {
    }

    open fun overrideConfigProperties(properties: List<ConfigProperty>): List<ConfigProperty> {
        return properties
    }

    private fun renderEmptyAsynchronousConfigInitializer(properties: List<ConfigProperty>) {
        writer.openBlock("public convenience required init() async throws {", "}") {
            writer.write("try await self.init(\$L)", properties.joinToString(", ") { "${it.name}: nil" })
        }
        writer.write("")
    }

    open fun renderPartitionID() {
        writer.openBlock("public var partitionID: String? {", "}") {
            writer.write("return \"\"")
        }
    }

    private fun renderLogHandlerFactory(serviceSymbol: Symbol) {
        writer.openBlock(
            "public struct \$LLogHandlerFactory: \$N {",
            "}",
            serviceSymbol.name,
            ClientRuntimeTypes.Core.SDKLogHandlerFactory
        ) {
            writer.write("public var label = \$S", serviceSymbol.name)
            writer.write("let logLevel: \$N", ClientRuntimeTypes.Core.SDKLogLevel)

            writer.openBlock("public func construct(label: String) -> LogHandler {", "}") {
                writer.write("var handler = StreamLogHandler.standardOutput(label: label)")
                writer.write("handler.logLevel = logLevel.toLoggerType()")
                writer.write("return handler")
            }

            writer.openBlock("public init(logLevel: \$N) {", "}", ClientRuntimeTypes.Core.SDKLogLevel) {
                writer.write("self.logLevel = logLevel")
            }
        }
        writer.write("")
    }

    data class ConfigClassVariablesCustomization(val serviceSymbol: Symbol) : CodeSection

    /**
     * Declare class variables in client configuration class
     */
    private fun renderConfigClassVariables(serviceSymbol: Symbol, properties: List<ConfigProperty>) {
        properties
            .forEach {
                writer.write("public var \$L: \$N", it.name, it.type)
                writer.write("")
            }
        writer.injectSection(ConfigClassVariablesCustomization(serviceSymbol))
        writer.write("")
    }

    data class ConfigInitializerCustomization(val serviceSymbol: Symbol) : CodeSection

    private fun renderConfigInitializer(serviceSymbol: Symbol, properties: List<ConfigProperty>) {
        writer.openBlock(
            "private init(\$L) {", "}",
            properties.joinToString(", ") { "_ ${it.name}: ${it.type.renderSwiftType()}" }
        ) {
            properties.forEach {
                writer.write("self.\$L = \$L", it.name, it.name)
            }
            writer.injectSection(ConfigInitializerCustomization(serviceSymbol))
        }
        writer.write("")
    }

    private fun renderSynchronousConfigInitializer(properties: List<ConfigProperty>) {
        writer.openBlock(
            "public convenience init(\$L) throws {", "}",
            properties.joinToString(", ") { "${it.name}: ${it.type.toOptional().renderSwiftType()} = nil" }
        ) {
            writer.write(
                "self.init(\$L)",
                properties.joinToString(", ") {
                    if (it.default?.isAsync == true) {
                        it.name
                    } else {
                        it.default?.render(it.name) ?: it.name
                    }
                }
            )
        }
        writer.write("")
    }

    private fun renderAsynchronousConfigInitializer(properties: List<ConfigProperty>) {
        if (properties.none { it.default?.isAsync == true }) return

        writer.openBlock(
            "public convenience init(\$L) async throws {", "}",
            properties.joinToString(", ") { "${it.name}: ${it.type.toOptional().renderSwiftType()} = nil" }
        ) {
            writer.write(
                "self.init(\$L)",
                properties.joinToString(", ") {
                    if (it.default?.isAsync == true) {
                        it.default.render()
                    } else {
                        it.default?.render(it.name) ?: it.name
                    }
                }
            )
        }
        writer.write("")
    }
    private fun renderServiceSpecificPlugins() {
        ctx.delegator.useFileWriter("./${ctx.settings.moduleName}/Plugins.swift") { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            ctx.integrations
                .flatMap { it.plugins(serviceConfig) }
                .onEach { it.render(ctx, writer) }
        }
    }
}
