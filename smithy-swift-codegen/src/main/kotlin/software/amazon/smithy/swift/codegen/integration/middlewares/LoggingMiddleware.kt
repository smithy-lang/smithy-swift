/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes

class LoggingMiddleware(
    private val model: Model,
    private val symbolProvider: SymbolProvider
) : MiddlewareRenderable {

    override val name = "LoggingMiddleware"

    override fun renderMiddlewareInit(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape
    ) {
        val input = MiddlewareShapeUtils.inputSymbol(ctx.symbolProvider, model, op)
        val output = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op)
        writer.write(
            "\$N<\$N, \$N>(\$L)",
            ClientRuntimeTypes.Middleware.LoggerMiddleware,
            input,
            output,
            middlewareParamsString(),
        )
    }

    private fun middlewareParamsString(): String {
        return "clientLogMode: config.clientLogMode"
    }
}
