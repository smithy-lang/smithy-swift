/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.IdempotencyTokenTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.ServiceGenerator
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep
import software.amazon.smithy.swift.codegen.model.hasTrait

class IdempotencyTokenMiddleware : MiddlewareRenderable {
    override val name = "IdempotencyTokenMiddleware"
    override val middlewareStep = MiddlewareStep.INITIALIZESTEP
    override val position = MiddlewarePosition.AFTER
    override fun render(model: Model, symbolProvider: SymbolProvider, writer: SwiftWriter, op: OperationShape, operationStackName: String) {

        val inputShape = model.expectShape(op.input.get())
        val idempotentMember = inputShape.members().firstOrNull { it.hasTrait<IdempotencyTokenTrait>() }
        idempotentMember?.let {
            val idempotentMemberName = it.memberName.decapitalize()
            val outputShapeName = ServiceGenerator.getOperationOutputShapeName(symbolProvider, model, op)
            val outputErrorShapeName = ServiceGenerator.getOperationErrorShapeName(op)
            writer.openBlock(
                "$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, id: \"${name}\") { (context, input, next) -> \$N<\$N<$outputShapeName>, \$N<$outputErrorShapeName>> in", "}",
                SwiftTypes.Result,
                ClientRuntimeTypes.Middleware.OperationOutput,
                ClientRuntimeTypes.Core.SdkError
            ) {
                writer.write("let idempotencyTokenGenerator = context.getIdempotencyTokenGenerator()")
                writer.write("var copiedInput = input")
                writer.openBlock("if input.$idempotentMemberName == nil {", "}") {
                    writer.write("copiedInput.$idempotentMemberName = idempotencyTokenGenerator.generateToken()")
                }
                writer.write("return next.handle(context: context, input: copiedInput)")
            }
        }
    }
}
