package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftWriter

/**
 * Represents a config field on a client config struct.
 */
data class ConfigField(val name: String?, val type: String, private val documentation: String? = null)

/**
 * ServiceConfig abstract class that allows configuration customizations to be configured for the protocol client generator
 */
abstract class ServiceConfig(val writer: SwiftWriter, val serviceName: String) {

    open val typeName: String = "${serviceName}Configuration"

    open val typesToConformConfigTo: List<String> = mutableListOf("SDKRuntimeConfiguration")

    fun getRuntimeConfigFields(): List<ConfigField> = mutableListOf(
        ConfigField("encoder", "RequestEncoder?"),
        ConfigField("decoder", "RequestDecoder?"),
        ConfigField("httpClientEngine", "HttpClientEngine"),
        ConfigField("httpClientConfiguration", "HttpClientConfiguration"),
        ConfigField("idempotencyTokenGenerator", "IdempotencyTokenGenerator"),
        ConfigField("retrier", "Retrier"),
        ConfigField("clientLogMode", "ClientLogMode"),
        ConfigField("logger", "LogAgent"))

    open fun getOtherConfigFields(): List<ConfigField> = listOf()

    fun getTypeInheritance(): String {
        return typesToConformConfigTo.joinToString(", ")
    }

    private fun renderMainInitializer(serviceSymbol: Symbol) {
        writer.openBlock("public init() throws {", "}") {
            writer.write("let defaultRuntimeConfig = try DefaultSDKRuntimeConfiguration(\"${serviceName}\")")
            writer.write("try self.init(runtimeConfig: defaultRuntimeConfig)")
        }
    }

    fun renderAllInitializers(serviceSymbol: Symbol) {
        renderMainInitializer(serviceSymbol)
        writer.write("")
        renderOtherInitializers(serviceSymbol)
    }

    open fun renderOtherInitializers(serviceSymbol: Symbol) {
        writer.openBlock("public init(runtimeConfig: SDKRuntimeConfiguration) throws {", "}") {
            val configFields = getRuntimeConfigFields().sortedBy { it.name }
            configFields.forEach {
                writer.write("self.${it.name} = runtimeConfig.${it.name}")
            }
        }
    }
}
