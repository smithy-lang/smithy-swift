/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.config

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.config.ClientConfiguration.Companion.runtimeSymbol
import software.amazon.smithy.swift.codegen.model.toNullable

class DefaultHttpClientConfiguration : ClientConfiguration {
    override val swiftProtocolName: Symbol
        get() = runtimeSymbol("DefaultHttpClientConfiguration", SwiftDependency.CLIENT_RUNTIME)

    override val properties: Set<ConfigProperty>
        get() = setOf(
            ConfigProperty("httpClientEngine", ClientRuntimeTypes.Http.HttpClient, "AWSClientConfigDefaultsProvider.httpClientEngine"),
            ConfigProperty("httpClientConfiguration", ClientRuntimeTypes.Http.HttpClientConfiguration, "AWSClientConfigDefaultsProvider.httpClientConfiguration"),
            ConfigProperty("authSchemes", ClientRuntimeTypes.Auth.AuthSchemes, "AWSClientConfigDefaultsProvider.authSchemes(serviceName)"),
            ConfigProperty("authSchemeResolver", ClientRuntimeTypes.Auth.AuthSchemeResolver, "")
        )
}
