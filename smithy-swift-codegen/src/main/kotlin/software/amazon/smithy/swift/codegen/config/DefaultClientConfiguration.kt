/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.config

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.config.ClientConfiguration.Companion.runtimeSymbol
import software.amazon.smithy.swift.codegen.model.toNullable

class DefaultClientConfiguration : ClientConfiguration {
    override val swiftProtocolName: Symbol
        get() = runtimeSymbol("DefaultClientConfiguration", SwiftDependency.CLIENT_RUNTIME)

    override val properties: Set<ConfigProperty>
        get() = setOf(
            ConfigProperty("logger", ClientRuntimeTypes.Core.Logger, "AWSClientConfigDefaultsProvider.logger(clientName)"),
            ConfigProperty("retryStrategyOptions", ClientRuntimeTypes.Core.RetryStrategyOptions, "AWSClientConfigDefaultsProvider.retryStrategyOptions()", true),
            ConfigProperty("clientLogMode", ClientRuntimeTypes.Core.ClientLogMode, "AWSClientConfigDefaultsProvider.clientLogMode"),
            ConfigProperty("endpoint", SwiftTypes.String.toNullable()),
            ConfigProperty("idempotencyTokenGenerator", ClientRuntimeTypes.Core.IdempotencyTokenGenerator, "AWSClientConfigDefaultsProvider.idempotencyTokenGenerator"),
        )
}
