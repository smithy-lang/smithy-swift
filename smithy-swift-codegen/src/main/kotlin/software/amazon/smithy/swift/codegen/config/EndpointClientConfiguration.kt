/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.config

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.rulesengine.traits.ClientContextParamsTrait
import software.amazon.smithy.swift.codegen.endpoint.ENDPOINT_RESOLVER
import software.amazon.smithy.swift.codegen.endpoint.EndpointSymbols
import software.amazon.smithy.swift.codegen.endpoint.toSwiftType
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.toOptional
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase

class EndpointClientConfiguration(val ctx: ProtocolGenerator.GenerationContext) : ClientConfiguration {
    override val swiftProtocolName: Symbol?
        get() = null

    override fun getProperties(ctx: ProtocolGenerator.GenerationContext): Set<ConfigProperty> {
        val properties: MutableSet<ConfigProperty> = mutableSetOf()
        val clientContextParams = ctx.service.getTrait<ClientContextParamsTrait>()
        clientContextParams?.parameters?.forEach {
            properties.add(ConfigProperty(it.key.toLowerCamelCase(), it.value.type.toSwiftType().toOptional()))
        }
        properties.add(ConfigProperty(ENDPOINT_RESOLVER, EndpointSymbols.EndpointResolver, "DefaultEndpointResolver()", true))
        return properties
    }
}
