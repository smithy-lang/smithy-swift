package software.amazon.smithy.swift.codegen.config

import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ServiceConfig

/**
 * Specifies the behaviour of the service configuration
 */
interface ClientConfiguration {
    /**
     * The protocol name of the client configuration
     */
    val swiftProtocolName: String

    /**
     *
     */
    fun protocolImplementation(writer: SwiftWriter, serviceConfig: ServiceConfig) {
    }
    fun addImport(writer: SwiftWriter) {
    }
}
