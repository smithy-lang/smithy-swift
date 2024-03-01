/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.config

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.Dependency
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.buildSymbol

/**
 * Specifies the behaviour of the service configuration
 */
interface ClientConfiguration {
    /**
     * The protocol name of the client configuration
     */
    val swiftProtocolName: Symbol?

    fun getProperties(ctx: ProtocolGenerator.GenerationContext): Set<ConfigProperty>

    companion object {
        fun runtimeSymbol(
            name: String,
            dependency: Dependency?,
        ): Symbol = buildSymbol {
            this.name = name
            dependency?.also {
                this.namespace = it.target
                dependency(dependency)
            }
        }
    }
}
