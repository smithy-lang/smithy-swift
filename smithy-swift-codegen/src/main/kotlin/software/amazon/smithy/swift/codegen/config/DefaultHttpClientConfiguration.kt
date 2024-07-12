/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.config

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.lang.AccessModifier
import software.amazon.smithy.swift.codegen.lang.Function
import software.amazon.smithy.swift.codegen.lang.FunctionParameter
import software.amazon.smithy.swift.codegen.model.toOptional
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAuthAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyIdentityTypes
import software.amazon.smithy.swift.codegen.utils.AuthUtils

class DefaultHttpClientConfiguration : ClientConfiguration {
    override val swiftProtocolName: Symbol = ClientRuntimeTypes.Core.DefaultHttpClientConfiguration

    override fun getProperties(ctx: ProtocolGenerator.GenerationContext): Set<ConfigProperty> = setOf(
        ConfigProperty(
            "httpClientEngine",
            SmithyHTTPAPITypes.HttpClient,
            { writer ->
                writer.format("\$N.makeClient(httpClientConfiguration: ", ClientRuntimeTypes.Core.ClientConfigurationDefaults) +
                    writer.format("httpClientConfiguration ?? \$N.defaultHttpClientConfiguration", ClientRuntimeTypes.Core.ClientConfigurationDefaults) +
                    ")"
            },
        ),
        ConfigProperty(
            "httpClientConfiguration",
            ClientRuntimeTypes.Http.HttpClientConfiguration,
            { it.format("\$N.defaultHttpClientConfiguration", ClientRuntimeTypes.Core.ClientConfigurationDefaults) },
        ),
        ConfigProperty("authSchemes", SmithyHTTPAuthAPITypes.AuthSchemes.toOptional(), AuthUtils(ctx).authSchemesDefaultProvider),
        ConfigProperty(
            "authSchemeResolver",
            SmithyHTTPAuthAPITypes.AuthSchemeResolver,
            { it.format("\$N.defaultAuthSchemeResolver", ClientRuntimeTypes.Core.ClientConfigurationDefaults) },
        ),
        ConfigProperty(
            "httpInterceptorProviders",
            ClientRuntimeTypes.Core.HttpInterceptorProviders,
            { "[]" },
            accessModifier = AccessModifier.PublicPrivateSet
        ),
        ConfigProperty(
            "bearerTokenIdentityResolver",
            SmithyIdentityTypes.BearerTokenIdentityResolver,
            { it.format("\$N()", SmithyIdentityTypes.StaticBearerTokenIdentityResolver) }
        )
    )

    override fun getMethods(ctx: ProtocolGenerator.GenerationContext): Set<Function> = setOf(
        Function(
            name = "addInterceptorProvider",
            renderBody = { writer -> writer.write("self.httpInterceptorProviders.append(provider)") },
            parameters = listOf(
                FunctionParameter.NoLabel("provider", ClientRuntimeTypes.Core.HttpInterceptorProvider)
            ),
        )
    )
}
