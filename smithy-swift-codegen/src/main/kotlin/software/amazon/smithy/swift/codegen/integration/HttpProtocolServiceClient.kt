/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter

open class HttpProtocolServiceClient(
    ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val properties: List<ClientProperty>,
    private val serviceConfig: ServiceConfig
) {
    private val serviceName: String = ctx.settings.sdkId

    fun render(serviceSymbol: Symbol) {
        writer.openBlock("public class ${serviceSymbol.name} {", "}") {
            writer.write("public static let clientName = \"${serviceSymbol.name}\"")
            writer.write("let client: \$N", ClientRuntimeTypes.Http.SdkHttpClient)
            writer.write("let config: \$L", serviceConfig.typeProtocol)
            writer.write("let serviceName = \"${serviceName}\"")
            writer.write("let encoder: \$N", ClientRuntimeTypes.Serde.RequestEncoder)
            writer.write("let decoder: \$N", ClientRuntimeTypes.Serde.ResponseDecoder)
            properties.forEach { prop ->
                prop.addImportsAndDependencies(writer)
            }
            writer.write("")
            writer.openBlock("public init(config: \$L) {", "}", serviceConfig.typeProtocol) {
                writer.write("client = \$N(engine: config.httpClientEngine, config: config.httpClientConfiguration)", ClientRuntimeTypes.Http.SdkHttpClient)
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
            renderConvenienceInit(serviceSymbol)
            writer.write("")
            renderConfig(serviceSymbol)
        }
        writer.write("")
        renderLogHandlerFactory(serviceSymbol)
        writer.write("")
    }

    open fun renderConvenienceInit(serviceSymbol: Symbol) {
        writer.openBlock("public convenience init() throws {", "}") {
            writer.write("let config = try ${serviceConfig.typeName}()")
            writer.write("self.init(config: config)")
        }
    }

    private fun renderLogHandlerFactory(serviceSymbol: Symbol) {
        writer.openBlock("public struct ${serviceSymbol.name}LogHandlerFactory: \$N {", "}", ClientRuntimeTypes.Core.SDKLogHandlerFactory) {
            writer.write("public var label = \"${serviceSymbol.name}\"")
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
    }

    private fun renderConfig(serviceSymbol: Symbol) {
        val sdkConfigs = serviceConfig.sdkRuntimeConfigProperties()
        val otherConfigs = serviceConfig.otherRuntimeConfigProperties()
        val serviceConfigs = serviceConfig.serviceConfigProperties()
        writer.openBlock("public class \$L: \$L {", "}", serviceConfig.typeName, serviceConfig.typeProtocol) {
            sdkConfigs.forEach {
                writer.write("public var ${it.memberName}: ${it.propFormatter}", it.variableType)
            }
            writer.write("")
            otherConfigs.forEach {
                writer.write("public var ${it.memberName}: ${it.propFormatter}", it.variableType)
            }

            writer.write("")
            serviceConfigs.forEach {
                writer.write("public var ${it.memberName}: ${it.propFormatter}", it.variableType)
            }

            writer.write("")
            serviceConfig.renderInitializers(serviceSymbol)
        }
    }
}
