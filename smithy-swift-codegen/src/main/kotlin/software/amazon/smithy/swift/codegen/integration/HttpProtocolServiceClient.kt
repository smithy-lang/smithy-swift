/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.plugins.DefaultClientPlugin
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase

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
            if (properties.any { it is HttpRequestEncoder }) {
                writer.write("let encoder: \$N", ClientRuntimeTypes.Serde.RequestEncoder)
            }
            if (properties.any { it is HttpResponseDecoder }) {
                writer.write("let decoder: \$N", ClientRuntimeTypes.Serde.ResponseDecoder)
            }
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
            writer.write("let config = try \$L(\"\$L\", \"\$L\")", serviceConfig.typeName, serviceName, serviceSymbol.name)
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
                    val customPlugins: MutableList<Plugin> = mutableListOf()

                    ctx.integrations
                        .flatMap { it.plugins() }
                        .onEach {
                            if (it.isDefault) {
                                defaultPlugins.add(it)
                            } else {
                                customPlugins.add(it)
                            }
                        }

                    val pluginsIterator = (defaultPlugins + customPlugins).iterator()

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
        writer.write(
            "public typealias \$LConfiguration = \$N",
            serviceConfig.clientName.toUpperCamelCase(),
            ClientRuntimeTypes.Core.DefaultSDKRuntimeConfiguration
        )
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
}
