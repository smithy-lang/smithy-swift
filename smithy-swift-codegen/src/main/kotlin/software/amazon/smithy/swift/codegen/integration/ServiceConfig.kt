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

    open val typesToConformConfigTo: List<String> = mutableListOf("ClientRuntime.Configuration")

    open fun getConfigFields(): List<ConfigField> = listOf()

    open fun renderStaticDefaultImplementation(serviceSymbol: Symbol) {
        writer.openBlock("public static func `default`() throws -> ${serviceSymbol.name}Configuration {", "}") {
            writer.write("return ${serviceSymbol.name}Configuration()")
        }
    }

    fun getTypeInheritance(): String {
        return typesToConformConfigTo.joinToString(", ")
    }

    open fun renderConvenienceInits(serviceSymbol: Symbol) {
        // pass none needed for default white label sdk config
    }
}
