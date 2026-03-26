/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyRetriesTypes

class RetryMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider,
    val retryErrorInfoProviderSymbol: Symbol,
    val retryErrorInfoProviderExpressionFactory: ((ProtocolGenerator.GenerationContext) -> String)? = null,
    val longPollingBackoffExpression: String? = null,
) : MiddlewareRenderable {
    override val name = "RetryMiddleware"

    override fun render(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String,
    ) {
        writer.write("builder.retryStrategy(\$N(options: config.retryStrategyOptions))", SmithyRetriesTypes.DefaultRetryStrategy)
        val expression = retryErrorInfoProviderExpressionFactory?.invoke(ctx)
        if (expression != null) {
            writer.write("builder.retryErrorInfoProvider($expression)")
        } else {
            writer.write("builder.retryErrorInfoProvider(\$N.errorInfo(for:))", retryErrorInfoProviderSymbol)
        }
        if (longPollingBackoffExpression != null) {
            writer.write("builder.longPollingBackoffProvider($longPollingBackoffExpression)")
        }
    }
}
