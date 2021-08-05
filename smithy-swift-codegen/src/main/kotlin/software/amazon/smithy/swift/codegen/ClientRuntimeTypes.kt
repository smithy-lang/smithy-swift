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
object ClientRuntimeTypes {
    object Http {
        val HttpClientEngine = runtimeSymbol("HttpClientEngine")
        val HttpClientConfiguration = runtimeSymbol("HttpClientConfiguration")
        val Headers = runtimeSymbol("Headers")
        val HttpStatusCode = runtimeSymbol("HttpStatusCode")
    }

    object Serde {
        val RequestEncoder = runtimeSymbol("RequestEncoder")
        val ResponseDecoder = runtimeSymbol("ResponseDecoder")
    }

    object Core {
        val Logger = runtimeSymbol("LogAgent")
        val ClientLogMode = runtimeSymbol("ClientLogMode")
        val IdempotencyTokenGenerator = runtimeSymbol("IdempotencyTokenGenerator")
        val Retrier = runtimeSymbol("Retrier")
        val ErrorType = runtimeSymbol("ErrorType", false)
    }
}

private fun runtimeSymbol(name: String, optional: Boolean = true): Symbol = buildSymbol {
    this.name = name
    this.nullable = optional
    dependency(SwiftDependency.CLIENT_RUNTIME)
}
