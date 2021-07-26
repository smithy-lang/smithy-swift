package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftWriter

/**
 * Represents a config field on a client config struct.
 */
data class ConfigField(val name: String?, val type: String, private val documentation: String?)

/**
 * ServiceConfig abstract class that allows configuration customizations to be configured for the protocol client generator
 */
abstract class ServiceConfig(val writer: SwiftWriter, val serviceName: String) {

    open val typeName: String = "${serviceName}Configuration"

    open val typesToConformConfigTo: List<String> = listOf()

    open fun getConfigFields(): List<ConfigField> = listOf()

    fun getTypeInheritance(): String {
        return typesToConformConfigTo.joinToString(", ")
    }

    open fun renderConvenienceInits(serviceSymbol: Symbol) {
        writer.openBlock("public convenience init() throws -> ${serviceName}Configuration {", "}") {
            writer.openBlock("try self.init(", ")") {
                val configFields = getConfigFields()
                configFields.forEachIndexed { index, configField ->
                    val terminator = if (index == configFields.lastIndex) "" else ","
                    writer.write("${configField.name}: ${configField.name}$terminator")
                }
            }
        }
    }
}
