/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.config

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.config.ClientConfiguration.Companion.runtimeSymbol
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.toOptional

class DefaultHttpClientConfiguration : ClientConfiguration {
    override val swiftProtocolName: Symbol
        get() = runtimeSymbol("DefaultHttpClientConfiguration", SwiftDependency.CLIENT_RUNTIME)

    override fun getProperties(ctx: ProtocolGenerator.GenerationContext): Set<ConfigProperty> = setOf(
        ConfigProperty(
            "httpClientEngine",
            ClientRuntimeTypes.Http.HttpClient,
            "DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>.makeClient()"
        ),
        ConfigProperty(
            "httpClientConfiguration",
            ClientRuntimeTypes.Http.HttpClientConfiguration,
            "DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>.defaultHttpClientConfiguration"
        ),
        ConfigProperty("authSchemes", ClientRuntimeTypes.Auth.AuthSchemes.toOptional()),
        ConfigProperty(
            "authSchemeResolver",
            ClientRuntimeTypes.Auth.AuthSchemeResolver,
            "DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>.defaultAuthSchemeResolver"
        )
    )
}
