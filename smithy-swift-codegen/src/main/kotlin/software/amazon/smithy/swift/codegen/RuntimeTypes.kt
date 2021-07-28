/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.model.buildSymbol

/**
 * Commonly used runtime types. Provides a single definition of a runtime symbol such that codegen isn't littered
 * with inline symbol creation which makes refactoring of the runtime more difficult and error prone.
 *
 * NOTE: Not all symbols need be added here but it doesn't hurt to define runtime symbols once.
 */
object RuntimeTypes {
    object Http {
        val HttpClientEngine = runtimeSymbol("HttpClientEngine", SwiftDependency.CLIENT_RUNTIME)
        val HttpClientConfiguration = runtimeSymbol("HttpClientConfiguration", SwiftDependency.CLIENT_RUNTIME)
    }

    object Serde {
        val RequestEncoder = runtimeSymbol("RequestEncoder", SwiftDependency.CLIENT_RUNTIME)
        val ResponseDecoder = runtimeSymbol("ResponseDecoder", SwiftDependency.CLIENT_RUNTIME)
    }

    object Core {
        val Logger = runtimeSymbol("LogAgent", SwiftDependency.CLIENT_RUNTIME)
        val ClientLogMode = runtimeSymbol("ClientLogMode", SwiftDependency.CLIENT_RUNTIME)
        val IdempotencyTokenGenerator = runtimeSymbol("IdempotencyTokenGenerator", SwiftDependency.CLIENT_RUNTIME)
        val Retrier = runtimeSymbol("Retrier", SwiftDependency.CLIENT_RUNTIME)
    }
}

private fun runtimeSymbol(name: String, dependency: SwiftDependency): Symbol = buildSymbol {
    this.name = name
    dependency(dependency)
}