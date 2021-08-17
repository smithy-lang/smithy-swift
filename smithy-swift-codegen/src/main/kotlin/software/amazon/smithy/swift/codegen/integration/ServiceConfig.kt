/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

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

    open val typesToConformConfigTo: List<Symbol> = mutableListOf(ClientRuntimeTypes.Core.SDKRuntimeConfiguration)

    fun sdkRuntimeConfigProperties(): List<ConfigField> {
        val configFields = mutableListOf(
            ConfigField("encoder", ClientRuntimeTypes.Serde.RequestEncoder),
            ConfigField("decoder", ClientRuntimeTypes.Serde.ResponseDecoder),
            ConfigField("httpClientEngine", ClientRuntimeTypes.Http.HttpClientEngine),
            ConfigField("httpClientConfiguration", ClientRuntimeTypes.Http.HttpClientConfiguration),
            ConfigField("idempotencyTokenGenerator", ClientRuntimeTypes.Core.IdempotencyTokenGenerator),
            ConfigField("retrier", ClientRuntimeTypes.Core.Retrier),
            ConfigField("clientLogMode", ClientRuntimeTypes.Core.ClientLogMode),
            ConfigField("logger", ClientRuntimeTypes.Core.Logger)
        ).sortedBy { it.memberName }
        return configFields
    }

    open fun otherRuntimeConfigProperties(): List<ConfigField> = listOf()

    fun getTypeInheritance(): String {
        return typesToConformConfigTo.joinToString(", ") { it.toString() }
    }

    open fun renderInitializers(serviceSymbol: Symbol) {
        writer.openBlock("public init(runtimeConfig: \$N) throws {", "}", ClientRuntimeTypes.Core.SDKRuntimeConfiguration) {
            val configFields = sdkRuntimeConfigProperties()
            configFields.forEach {
                writer.write("self.${it.memberName} = runtimeConfig.${it.memberName}")
            }
        }
        writer.write("")
        writer.openBlock("public convenience init() throws {", "}") {
            writer.write("let defaultRuntimeConfig = try \$N(\"${serviceName}\")", ClientRuntimeTypes.Core.DefaultSDKRuntimeConfiguration)
            writer.write("try self.init(runtimeConfig: defaultRuntimeConfig)")
        }
    }
}
