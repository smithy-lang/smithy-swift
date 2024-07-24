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
) : MiddlewareRenderable {
    override val name = "RetryMiddleware"

    override fun render(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape, operationStackName: String) {
        writer.write("builder.retryStrategy(\$N(options: config.retryStrategyOptions))", SmithyRetriesTypes.DefaultRetryStrategy)
        writer.write("builder.retryErrorInfoProvider(\$N.errorInfo(for:))", retryErrorInfoProviderSymbol)
    }
}
