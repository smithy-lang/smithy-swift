package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
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

    fun sdkRuntimeConfigFields(): List<ConfigField> = mutableListOf(
        ConfigField("encoder", ClientRuntimeTypes.Serde.RequestEncoder),
        ConfigField("decoder", ClientRuntimeTypes.Serde.ResponseDecoder),
        ConfigField("httpClientEngine", ClientRuntimeTypes.Http.HttpClientEngine),
        ConfigField("httpClientConfiguration", ClientRuntimeTypes.Http.HttpClientConfiguration),
        ConfigField("idempotencyTokenGenerator", ClientRuntimeTypes.Core.IdempotencyTokenGenerator),
        ConfigField("retrier", ClientRuntimeTypes.Core.Retrier),
        ConfigField("clientLogMode", ClientRuntimeTypes.Core.ClientLogMode),
        ConfigField("logger", ClientRuntimeTypes.Core.Logger)
    )

    open fun getOtherConfigFields(): List<ConfigField> = listOf()

    fun getTypeInheritance(): String {
        return typesToConformConfigTo.joinToString(", ")
    }

    open fun renderInitializers(serviceSymbol: Symbol) {
        writer.openBlock("public init(runtimeConfig: SDKRuntimeConfiguration) throws {", "}") {
            val configFields = sdkRuntimeConfigFields().sortedBy { it.memberName }
            configFields.forEach {
                writer.write("self.${it.memberName} = runtimeConfig.${it.memberName}")
            }
        }
        writer.write("")
        writer.openBlock("public convenience init() throws {", "}") {
            writer.write("let defaultRuntimeConfig = try DefaultSDKRuntimeConfiguration(\"${serviceName}\")")
            writer.write("try self.init(runtimeConfig: defaultRuntimeConfig)")
        }
    }
}
