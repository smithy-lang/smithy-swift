package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
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
            writer.write("let client: SdkHttpClient")
            writer.write("let config: ${serviceConfig.typeName}")
            writer.write("let serviceName = \"${serviceName}\"")
            writer.write("let encoder: RequestEncoder")
            writer.write("let decoder: ResponseDecoder")
            properties.forEach { prop ->
                prop.addImportsAndDependencies(writer)
            }
            writer.write("")
            writer.openBlock("public init(config: ${serviceSymbol.name}Configuration) {", "}") {
                writer.write("client = SdkHttpClient(engine: config.httpClientEngine, config: config.httpClientConfiguration)")
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
            writer.openBlock("deinit {", "}") {
                writer.write("client.close()")
            }
            writer.write("")
            renderConfig(serviceSymbol)
        }
        writer.write("")
        renderLogHandlerFactory(serviceSymbol)
        writer.write("")
    }

    private fun renderLogHandlerFactory(serviceSymbol: Symbol) {
        writer.openBlock("public struct ${serviceSymbol.name}LogHandlerFactory: SDKLogHandlerFactory {", "}") {
            writer.write("public var label = \"${serviceSymbol.name}\"")
            writer.write("let logLevel: SDKLogLevel")

            writer.openBlock("public func construct(label: String) -> LogHandler {", "}") {
                writer.write("var handler = StreamLogHandler.standardOutput(label: label)")
                writer.write("handler.logLevel = logLevel.toLoggerType()")
                writer.write("return handler")
            }

            writer.openBlock("public init(logLevel: SDKLogLevel) {", "}") {
                writer.write("self.logLevel = logLevel")
            }
        }
    }

    private fun renderConfig(serviceSymbol: Symbol) {

        val configFields = serviceConfig.getConfigFields()
        val inheritance = serviceConfig.getTypeInheritance()
        writer.openBlock("public class ${serviceSymbol.name}Configuration: $inheritance {", "}") {
            writer.write("")
            configFields.forEach {
                writer.write("public var ${it.name}: ${it.type}")
            }
            writer.write("")
            writer.write("public let clientLogMode: ClientLogMode")
            writer.write("public let logger: LogAgent")
            writer.write("")
            renderConfigInit(configFields, serviceSymbol)
            writer.write("")
            serviceConfig.renderConvenienceInits(serviceSymbol)
            writer.write("")
            serviceConfig.renderStaticDefaultImplementation(serviceSymbol)
        }
    }

    private fun renderConfigInit(configFields: List<ConfigField>, serviceSymbol: Symbol) {
        if (configFields.isNotEmpty()) {
            val configFieldsSortedByName = configFields.sortedBy { it.name }
            writer.openBlock("public init (", ") throws") {
                for (member in configFieldsSortedByName) {
                    val memberName = member.name
                    val memberSymbol = member.type
                    if (memberName == null) continue
                    writer.write("\$L: \$L,", memberName, memberSymbol)
                }
                writer.write("clientLogMode: ClientLogMode = .request,")
                writer.write("logger: LogAgent? = nil")
            }
            writer.openBlock("{", "}") {
                configFieldsSortedByName.forEach {
                    writer.write("self.\$1L = \$1L", it.name)
                }
                writer.write("self.clientLogMode = clientLogMode")
                writer.write("self.logger = logger ?? SwiftLogger(label: \"${serviceSymbol.name}\")")
            }
        }
    }
}
