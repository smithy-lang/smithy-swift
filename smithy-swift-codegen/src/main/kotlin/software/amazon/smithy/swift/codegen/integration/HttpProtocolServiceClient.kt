/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase

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
            writer.write("let config: \$L", serviceConfig.typeName)
            writer.write("let serviceName = \"${serviceName}\"")
            writer.write("let encoder: \$N", ClientRuntimeTypes.Serde.RequestEncoder)
            writer.write("let decoder: \$N", ClientRuntimeTypes.Serde.ResponseDecoder)
            writer.write("")
            properties.forEach { prop ->
                prop.addImportsAndDependencies(writer)
            }
            renderInitFunction(properties)
            writer.write("")
            renderConvenienceInitFunctions(serviceSymbol)
        }
        writer.write("")
        renderServiceExtension(serviceSymbol)
        renderLogHandlerFactory(serviceSymbol)
    }

    open fun renderInitFunction(properties: List<ClientProperty>) {
        writer.openBlock("public init(config: \$L) {", "}", serviceConfig.typeName) {
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
        writer.openBlock("public convenience init() throws {", "}") {
            writer.write("let config = try ${serviceConfig.typeName}(\"${serviceName}\", \"${serviceSymbol.name}\")")
            writer.write("self.init(config: config)")
        }
        writer.write("")
    }

    open fun renderServiceExtension(serviceSymbol: Symbol) {
        writer.openBlock("extension ${serviceSymbol.name} {", "}") {
            writer.write(
                "public typealias \$LConfiguration = \$N",
                serviceConfig.clientName.toUpperCamelCase(),
                ClientRuntimeTypes.Core.DefaultSDKRuntimeConfiguration
            )
        }
        writer.write("")
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
        writer.write("")
    }
}
