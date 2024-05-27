/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyRetriesTypes

class RetryMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider,
    val retryErrorInfoProviderSymbol: Symbol,
) : MiddlewareRenderable {

    override val name = "RetryMiddleware"

    override val middlewareStep = MiddlewareStep.FINALIZESTEP

    override val position = MiddlewarePosition.AFTER

    override fun render(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape, operationStackName: String) {
        if (ctx.settings.useInterceptors) {
            writer.addImport(SwiftDependency.SMITHY_RETRIES.target)
            writer.write("builder.retryStrategy(\$N(options: config.retryStrategyOptions))", SmithyRetriesTypes.DefaultRetryStrategy)
            writer.write("builder.retryErrorInfoProvider(\$N.errorInfo(for:))", retryErrorInfoProviderSymbol)
        } else {
            val output = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op)
            writer.addImport(SwiftDependency.SMITHY_RETRIES.target)
            writer.write(
                "\$L.\$L.intercept(position: \$L, middleware: \$N<\$N, \$N, \$N>(options: config.retryStrategyOptions))",
                operationStackName,
                middlewareStep.stringValue(),
                position.stringValue(),
                ClientRuntimeTypes.Middleware.RetryMiddleware,
                SmithyRetriesTypes.DefaultRetryStrategy,
                retryErrorInfoProviderSymbol,
                output
            )
        }
    }
}
