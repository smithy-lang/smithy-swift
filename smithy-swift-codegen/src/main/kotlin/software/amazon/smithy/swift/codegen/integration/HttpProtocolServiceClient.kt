/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.config.ConfigProperty
import software.amazon.smithy.swift.codegen.integration.plugins.DefaultClientPlugin
import software.amazon.smithy.swift.codegen.integration.serde.SerdeUtils
import software.amazon.smithy.swift.codegen.model.renderSwiftType
import software.amazon.smithy.swift.codegen.model.toOptional
import software.amazon.smithy.swift.codegen.protocols.rpcv2cbor.RPCv2CBORPlugin
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase
import software.amazon.smithy.utils.CodeSection

open class HttpProtocolServiceClient(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val serviceConfig: ServiceConfig,
) {
    private val serviceName: String = ctx.settings.sdkIdStrippingService

    open val clientProtocolSymbol: Symbol = ClientRuntimeTypes.Core.Client

    fun render(serviceSymbol: Symbol) {
        writer.openBlock(
            "${ctx.settings.visibility} final class \$L: \$N {",
            "}",
            serviceSymbol.name,
            clientProtocolSymbol,
        ) {
            writer.write("public static let clientName = \$S", serviceSymbol.name)
            renderVersionProperty()
            writer.write("let client: \$N", ClientRuntimeTypes.Http.SdkHttpClient)
            writer.write("public let config: \$L", serviceConfig.sendableTypeName)
            writer.write("let serviceName = \$S", serviceName)
            writer.write("")
            // Add Config typealias for backward compatibility - points to deprecated class
            // This satisfies the Client protocol's associated type requirement
            writer.write("@available(*, deprecated, message: \"Use \$L instead\")", serviceConfig.sendableTypeName)
            writer.write("public typealias Config = \$L", serviceConfig.typeName)
            writer.write("public typealias Configuration = \$L", serviceConfig.sendableTypeName)
            writer.write("")
            renderInitFunction()
            writer.write("")
            renderDeprecatedInitFunction()
            writer.write("")
            renderConvenienceInitFunctions(serviceSymbol)
        }
        writer.write("")
        renderClientExtension(serviceSymbol)
        renderServiceSpecificPlugins()
    }

    open fun renderVersionProperty() {
        writer.write("public static let version = \$S", ctx.settings.moduleVersion)
    }

    open fun renderInitFunction() {
        writer.openBlock("public required init(config: \$L) {", "}", serviceConfig.sendableTypeName) {
            writer.write("\$N()", ClientRuntimeTypes.Core.initialize)
            writer.write(
                "client = \$N(engine: config.httpClientEngine, config: config.httpClientConfiguration)",
                ClientRuntimeTypes.Http.SdkHttpClient,
            )
            writer.write("self.config = config")
        }
        writer.write("")
    }

    open fun renderDeprecatedInitFunction() {
        // Convenience init for backward compatibility with the deprecated class
        // The Client protocol's Config associated type is inferred from the required init, not the typealias
        writer.write(
            "@available(*, deprecated, message: \"Use init(config: \$L) instead\")",
            serviceConfig.sendableTypeName,
        )
        writer.openBlock("public convenience init(config: \$L) {", "}", serviceConfig.typeName) {
            writer.openBlock("do {", "} catch {") {
                writer.write("try self.init(config: config.toSendable())")
            }
            writer.indent()
            writer.write("// This should never happen since all values are already initialized in the class")
            writer.write("fatalError(\"Failed to convert deprecated configuration: \\(error)\")")
            writer.dedent()
            writer.write("}")
        }
        writer.write("")
    }

    open fun renderConvenienceInitFunctions(serviceSymbol: Symbol) {
        writer.openBlock("public convenience init() throws {", "}") {
            writer.write("let config = try \$L()", serviceConfig.sendableTypeName)
            writer.write("self.init(config: config)")
        }
        writer.write("")
    }

    fun renderClientExtension(serviceSymbol: Symbol) {
        writer.openBlock("extension \$L {", "}", serviceSymbol.name) {
            writer.write("")
            renderClientConfigSendable(serviceSymbol)
            writer.write("")
            renderDeprecatedClientConfigClass(serviceSymbol)
            writer.write("")

            writer.openBlock(
                "public static func builder() -> \$N<\$L> {",
                "}",
                ClientRuntimeTypes.Core.ClientBuilder,
                serviceSymbol.name,
            ) {
                writer.openBlock(
                    "return \$N<\$L>(defaultPlugins: [",
                    "])",
                    ClientRuntimeTypes.Core.ClientBuilder,
                    serviceSymbol.name,
                ) {
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

    open fun renderClientConfigSendable(serviceSymbol: Symbol) {
        val clientConfigurationProtocols =
            ctx.integrations
                .flatMap { it.clientConfigurations(ctx) }
                .mapNotNull { it.swiftProtocolName }
                .map { writer.format("\$N", it) }
                .joinToString(" & ")

        writer.write("/// Client configuration for \$L", serviceConfig.clientName)
        writer.write("///")
        writer.write("/// Conforms to `Sendable` for safe concurrent access across threads.")
        writer.openBlock(
            "public struct \$LConfig: \$L, \$N {",
            "}",
            serviceConfig.clientName.toUpperCamelCase(),
            clientConfigurationProtocols,
            SwiftTypes.Protocols.Sendable,
        ) {
            val clientConfigs = ctx.integrations.flatMap { it.clientConfigurations(ctx) }
            val properties: List<ConfigProperty> =
                clientConfigs
                    .flatMap { it.getProperties(ctx) }
                    .let { overrideConfigProperties(it) }
                    .sortedBy { it.accessModifier }

            renderConfigClassVariables(serviceSymbol, properties)

            renderSynchronousConfigInitializer(serviceSymbol, properties)

            renderAsynchronousConfigInitializer(serviceSymbol, properties)

            renderEmptyAsynchronousConfigInitializer(serviceSymbol, properties, isClass = false)

            renderCustomConfigInitializer(properties)

            renderPartitionID()

            clientConfigs
                .flatMap { it.getMethods(ctx) }
                .sortedBy { it.accessModifier }
                .forEach {
                    it.render(writer)
                    writer.write("")
                }
        }
        writer.write("")
    }

    open fun renderDeprecatedClientConfigClass(serviceSymbol: Symbol) {
        val clientConfigurationProtocols =
            ctx.integrations
                .flatMap { it.clientConfigurations(ctx) }
                .mapNotNull { it.swiftProtocolName }
                .map { writer.format("\$N", it) }
                .joinToString(" & ")

        writer.write(
            "@available(*, deprecated, message: \"Use \$LConfig instead. This class will be removed in a future version.\")",
            serviceConfig.clientName.toUpperCamelCase(),
        )
        writer.openBlock(
            "public final class \$LConfiguration: \$L {",
            "}",
            serviceConfig.clientName.toUpperCamelCase(),
            clientConfigurationProtocols,
        ) {
            val clientConfigs = ctx.integrations.flatMap { it.clientConfigurations(ctx) }
            val properties: List<ConfigProperty> =
                clientConfigs
                    .flatMap { it.getProperties(ctx) }
                    .let { overrideConfigProperties(it) }
                    .sortedBy { it.accessModifier }

            renderConfigClassVariables(serviceSymbol, properties)

            renderSynchronousConfigInitializer(serviceSymbol, properties)

            renderAsynchronousConfigInitializer(serviceSymbol, properties)

            renderEmptyAsynchronousConfigInitializer(serviceSymbol, properties, isClass = true)

            renderCustomConfigInitializerForDeprecatedClass(properties)

            renderPartitionID()

            renderToSendableMethod(properties)

            // Render methods without 'mutating' keyword for class
            clientConfigs
                .flatMap { it.getMethods(ctx) }
                .sortedBy { it.accessModifier }
                .forEach { method ->
                    // Create a copy of the method without the mutating keyword for classes
                    val nonMutatingMethod = method.copy(isMutating = false)
                    nonMutatingMethod.render(writer)
                    writer.write("")
                }
        }
        writer.write("")
    }

    private fun renderToSendableMethod(properties: List<ConfigProperty>) {
        writer.openBlock(
            "public func toSendable() throws -> \$LConfig {",
            "}",
            serviceConfig.clientName.toUpperCamelCase(),
        ) {
            writer.openBlock(
                "return try \$LConfig(",
                ")",
                serviceConfig.clientName.toUpperCamelCase(),
            ) {
                properties.forEach { property ->
                    // Don't wrap interceptor providers - they're already in the correct format
                    // The struct's initializer will handle the wrapping
                    writer.write("\$L: self.\$L,", property.name, property.name)
                }
                writer.unwrite(",\n")
                writer.write("")
            }
        }
        writer.write("")
    }

    open fun renderCustomConfigInitializer(properties: List<ConfigProperty>) {
    }

    open fun renderCustomConfigInitializerForDeprecatedClass(properties: List<ConfigProperty>) {
        // By default, same as the struct version
        renderCustomConfigInitializer(properties)
    }

    open fun overrideConfigProperties(properties: List<ConfigProperty>): List<ConfigProperty> = properties

    private fun renderEmptyAsynchronousConfigInitializer(
        serviceSymbol: Symbol,
        properties: List<ConfigProperty>,
        isClass: Boolean = false,
    ) {
        val convenienceKeyword = if (isClass) "convenience " else ""
        writer.openBlock("public ${convenienceKeyword}init() async throws {", "}") {
            // Call the parameterized async initializer with all nil parameters
            // This delegates to the async initializer which properly handles async defaults
            writer.openBlock("try await self.init(", ")") {
                properties.forEach { property ->
                    writer.write("\$L: nil,", property.name)
                }
                writer.unwrite(",\n")
                writer.write("")
            }
        }
        writer.write("")
    }

    open fun renderPartitionID() {
        writer.openBlock("public var partitionID: String? {", "}") {
            writer.write("return \"\"")
        }
        writer.write("")
    }

    data class ConfigClassVariablesCustomization(
        val serviceSymbol: Symbol,
    ) : CodeSection

    /**
     * Declare class variables in client configuration class
     */
    private fun renderConfigClassVariables(
        serviceSymbol: Symbol,
        properties: List<ConfigProperty>,
    ) {
        // Render normal properties
        properties.filter { it.name != "interceptorProviders" && it.name != "httpInterceptorProviders" }.forEach {
            it.render(writer)
        }

        // Render interceptor provider properties with private storage and public computed properties
        writer.write("// Interceptor providers with Sendable-safe internal storage")
        writer.write("private var _interceptorProviders: [\$N] = []", ClientRuntimeTypes.Core.SendableInterceptorProviderBox)
        writer.openBlock("public var interceptorProviders: [\$N] {", "}", ClientRuntimeTypes.Core.InterceptorProvider) {
            writer.openBlock("get {", "}") {
                writer.write("return _interceptorProviders")
            }
            writer.openBlock("set {", "}") {
                writer.write("_interceptorProviders = newValue.map { \$N(\$\$0) }", ClientRuntimeTypes.Core.SendableInterceptorProviderBox)
            }
        }
        writer.write("")
        writer.write("private var _httpInterceptorProviders: [\$N] = []", ClientRuntimeTypes.Core.SendableHttpInterceptorProviderBox)
        writer.openBlock("public var httpInterceptorProviders: [\$N] {", "}", ClientRuntimeTypes.Core.HttpInterceptorProvider) {
            writer.openBlock("get {", "}") {
                writer.write("return _httpInterceptorProviders")
            }
            writer.openBlock("set {", "}") {
                writer.write(
                    "_httpInterceptorProviders = newValue.map { \$N(\$\$0) }",
                    ClientRuntimeTypes.Core.SendableHttpInterceptorProviderBox,
                )
            }
        }

        writer.injectSection(ConfigClassVariablesCustomization(serviceSymbol))
        writer.write("")
    }

    data class ConfigInitializerCustomization(
        val serviceSymbol: Symbol,
    ) : CodeSection

    private fun renderSynchronousConfigInitializer(
        serviceSymbol: Symbol,
        properties: List<ConfigProperty>,
    ) {
        writer.openBlock("public init(", ") throws {") {
            properties.forEach { property ->
                writer.write("\$L: \$N = nil,", property.name, property.type.toOptional())
            }
            writer.unwrite(",\n")
            writer.write("")
        }
        writer.indent {
            properties.filter { it.name != "interceptorProviders" && it.name != "httpInterceptorProviders" }.forEach { property ->
                if (property.default?.isAsync == true) {
                    writer.write("self.\$L = \$L", property.name, property.name)
                } else {
                    writer.write("self.\$L = \$L", property.name, property.default?.render(writer, property.name) ?: property.name)
                }
            }
            // Handle interceptor providers specially - wrap them when storing
            writer.write(
                "self._interceptorProviders = (interceptorProviders ?? []).map { \$N(\$\$0) }",
                ClientRuntimeTypes.Core.SendableInterceptorProviderBox,
            )
            writer.write(
                "self._httpInterceptorProviders = (httpInterceptorProviders ?? []).map { \$N(\$\$0) }",
                ClientRuntimeTypes.Core.SendableHttpInterceptorProviderBox,
            )
            writer.injectSection(ConfigInitializerCustomization(serviceSymbol))
        }
        writer.write("}")
        writer.write("")
    }

    private fun renderAsynchronousConfigInitializer(
        serviceSymbol: Symbol,
        properties: List<ConfigProperty>,
    ) {
        if (properties.none { it.default?.isAsync == true }) return

        writer.openBlock("public init(", ") async throws {") {
            properties.forEach { property ->
                writer.write("\$L: \$L = nil,", property.name, property.type.toOptional().renderSwiftType(writer))
            }
            writer.unwrite(",\n")
            writer.write("")
        }
        writer.indent {
            properties.filter { it.name != "interceptorProviders" && it.name != "httpInterceptorProviders" }.forEach { property ->
                if (property.default?.isAsync == true) {
                    writer.write("self.\$L = \$L", property.name, property.default.render(writer))
                } else {
                    writer.write("self.\$L = \$L", property.name, property.default?.render(writer, property.name) ?: property.name)
                }
            }
            // Handle interceptor providers specially - wrap them when storing
            writer.write(
                "self._interceptorProviders = (interceptorProviders ?? []).map { \$N(\$\$0) }",
                ClientRuntimeTypes.Core.SendableInterceptorProviderBox,
            )
            writer.write(
                "self._httpInterceptorProviders = (httpInterceptorProviders ?? []).map { \$N(\$\$0) }",
                ClientRuntimeTypes.Core.SendableHttpInterceptorProviderBox,
            )
            writer.injectSection(ConfigInitializerCustomization(serviceSymbol))
        }
        writer.write("}")
        writer.write("")
    }

    private fun renderServiceSpecificPlugins() {
        ctx.delegator.useFileWriter("Sources/${ctx.settings.moduleName}/Plugins.swift") { writer ->
            ctx.integrations
                .flatMap { it.plugins(serviceConfig) }
                .onEach { it.render(ctx, writer) }
        }
    }
}
