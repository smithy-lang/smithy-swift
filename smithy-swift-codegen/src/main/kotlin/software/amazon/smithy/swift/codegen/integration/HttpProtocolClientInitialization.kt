package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftWriter

open class HttpProtocolClientInitialization(
    ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val properties: List<ClientProperty>,
    private val serviceConfig: ServiceConfig
) {
    private val serviceName: String = ctx.settings.sdkId

    fun renderClientInitialization(serviceSymbol: Symbol) {
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
            // FIXME: possible move generation of the config to a separate file or above the service client
            renderConfig(serviceSymbol)
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
            renderConfigInit(configFields)
            writer.write("")
            serviceConfig.renderConvenienceInits(serviceSymbol)
            writer.write("")
            serviceConfig.renderStaticDefaultImplementation(serviceSymbol)
        }
    }

    private fun renderConfigInit(configFields: List<ConfigField>) {
        if (configFields.isNotEmpty()) {
            val configFieldsSortedByName = configFields.sortedBy { it.name }
            writer.openBlock("public init (", ") throws") {
                for ((index, member) in configFieldsSortedByName.withIndex()) {
                    val memberName = member.name
                    val memberSymbol = member.type
                    if (memberName == null) continue
                    val terminator = if (index == configFieldsSortedByName.size - 1) "" else ","
                    writer.write("\$L: \$L$terminator", memberName, memberSymbol)
                }
            }
            writer.openBlock("{", "}") {
                configFieldsSortedByName.forEach {
                    writer.write("self.\$1L = \$1L", it.name)
                }
            }
        }
    }
}
