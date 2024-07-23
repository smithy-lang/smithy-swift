/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.IdempotencyTokenTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes

class IdempotencyTokenMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider
) : MiddlewareRenderable {
    override val name = "IdempotencyTokenMiddleware"

    override fun render(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape, operationStackName: String) {
        val inputShape = model.expectShape(op.input.get())
        val idempotentMember = inputShape.members().firstOrNull { it.hasTrait<IdempotencyTokenTrait>() }
        idempotentMember?.let {
            super.render(ctx, writer, op, operationStackName)
        }
    }

    override fun renderMiddlewareInit(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape
    ) {
        val inputShape = model.expectShape(op.input.get())
        val idempotentMember = inputShape.members().firstOrNull { it.hasTrait<IdempotencyTokenTrait>() }
        idempotentMember?.let {
            val idempotentMemberName = it.memberName.decapitalize()
            val inputShapeName = MiddlewareShapeUtils.inputSymbol(symbolProvider, model, op).name
            val outputShapeName = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op).name

            writer.write(
                "\$N<\$L, \$L>(keyPath: \\.\$L)",
                ClientRuntimeTypes.Middleware.IdempotencyTokenMiddleware,
                inputShapeName,
                outputShapeName,
                idempotentMemberName,
            )
        }
    }
}
