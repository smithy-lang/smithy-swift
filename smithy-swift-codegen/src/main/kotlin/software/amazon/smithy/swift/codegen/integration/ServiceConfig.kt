package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.RuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter

/**
 * Represents a config field on a client config struct.
 */
data class ConfigField(val memberName: String?, val type: Symbol, private val documentation: String? = null)

/**
 * ServiceConfig abstract class that allows configuration customizations to be configured for the protocol client generator
 */
abstract class ServiceConfig(val writer: SwiftWriter, val serviceName: String) {

    open val typeName: String = "${serviceName}Configuration"

    open val typesToConformConfigTo: List<String> = mutableListOf("SDKRuntimeConfiguration")

    fun getRuntimeConfigFields(): List<ConfigField> = mutableListOf(
        ConfigField("encoder", RuntimeTypes.Serde.RequestEncoder),
        ConfigField("decoder", RuntimeTypes.Serde.ResponseDecoder),
        ConfigField("httpClientEngine", RuntimeTypes.Http.HttpClientEngine),
        ConfigField("httpClientConfiguration", RuntimeTypes.Http.HttpClientConfiguration),
        ConfigField("idempotencyTokenGenerator", RuntimeTypes.Core.IdempotencyTokenGenerator),
        ConfigField("retrier", RuntimeTypes.Core.Retrier),
        ConfigField("clientLogMode", RuntimeTypes.Core.ClientLogMode),
        ConfigField("logger", RuntimeTypes.Core.Logger)
    )

    open fun getOtherConfigFields(): List<ConfigField> = listOf()

    fun getTypeInheritance(): String {
        return typesToConformConfigTo.joinToString(", ")
    }

    open fun renderMainInitializer(serviceSymbol: Symbol) {
        writer.openBlock("public init(runtimeConfig: SDKRuntimeConfiguration) throws {", "}") {
            val configFields = getRuntimeConfigFields().sortedBy { it.memberName }
            configFields.forEach {
                writer.write("self.${it.memberName} = runtimeConfig.${it.memberName}")
            }
        }
    }

    fun renderAllInitializers(serviceSymbol: Symbol) {
        renderMainInitializer(serviceSymbol)
        writer.write("")
        renderConvenienceInitializers(serviceSymbol)
    }

    open fun renderConvenienceInitializers(serviceSymbol: Symbol) {
        writer.openBlock("public convenience init() throws {", "}") {
            writer.write("let defaultRuntimeConfig = try DefaultSDKRuntimeConfiguration(\"${serviceName}\")")
            writer.write("try self.init(runtimeConfig: defaultRuntimeConfig)")
        }
    }
}
