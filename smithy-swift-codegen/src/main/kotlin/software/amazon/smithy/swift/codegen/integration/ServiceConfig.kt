/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.model.buildSymbol
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase

/**
 * Represents a config field on a client config struct.
 */
data class ConfigField(val memberName: String?, val type: Symbol, val propFormatter: String = "\$N", private val documentation: String? = null, val paramFormatter: String = "\$D")

/**
 * ServiceConfig abstract class that allows configuration customizations to be configured for the protocol client generator
 */
abstract class ServiceConfig(val writer: SwiftWriter, val clientName: String, val serviceName: String) {

    open val typeName: String = "${clientName.toUpperCamelCase()}.${clientName.toUpperCamelCase()}Configuration"

    fun sdkRuntimeConfigProperties(): List<ConfigField> {
        val configFields = mutableListOf(
            ConfigField("encoder", ClientRuntimeTypes.Serde.RequestEncoder, propFormatter = "\$T"),
            ConfigField("decoder", ClientRuntimeTypes.Serde.ResponseDecoder, propFormatter = "\$T"),
            ConfigField("httpClientEngine", ClientRuntimeTypes.Http.HttpClientEngine),
            ConfigField("httpClientConfiguration", ClientRuntimeTypes.Http.HttpClientConfiguration),
            ConfigField("idempotencyTokenGenerator", ClientRuntimeTypes.Core.IdempotencyTokenGenerator),
            ConfigField("retryStrategyOptions", ClientRuntimeTypes.Core.RetryStrategyOptions),
            ConfigField("clientLogMode", ClientRuntimeTypes.Core.ClientLogMode),
            ConfigField("logger", ClientRuntimeTypes.Core.Logger)
        ).sortedBy { it.memberName }
        return configFields
    }

    open fun otherRuntimeConfigProperties(): List<ConfigField> = listOf()

    open fun renderInitializers(serviceSymbol: Symbol) {
        writer.openBlock("public init(runtimeConfig: \$N) throws {", "}", ClientRuntimeTypes.Core.DefaultSDKRuntimeConfiguration) {
            val configFields = sdkRuntimeConfigProperties()
            configFields.forEach {
                writer.write("self.${it.memberName} = runtimeConfig.${it.memberName}")
            }
        }
        writer.write("")
        writer.openBlock("public convenience init() throws {", "}") {
            writer.write("let defaultRuntimeConfig = try \$N(\"${clientName}\")", ClientRuntimeTypes.Core.DefaultSDKRuntimeConfiguration)
            writer.write("try self.init(runtimeConfig: defaultRuntimeConfig)")
        }
    }

    open fun serviceConfigProperties(): List<ConfigField> = listOf()
}

object ServiceTypes {
    val AuthSchemes = symbol("[ClientRuntime.AuthScheme]")
    val AuthSchemeResolver = symbol("ClientRuntime.AuthSchemeResolver")
    val AuthSchemeResolverParams = symbol("ClientRuntime.AuthSchemeResolverParameters")

    private fun symbol(name: String): Symbol = buildSymbol {
        this.name = name
    }
}
