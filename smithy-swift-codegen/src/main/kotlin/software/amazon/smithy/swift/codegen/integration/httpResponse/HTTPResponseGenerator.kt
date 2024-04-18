/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.integration.HTTPProtocolCustomizable
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class HTTPResponseGenerator(
    val customizations: HTTPProtocolCustomizable,
) {
    val httpResponseBindingOutputGenerator = HTTPResponseBindingOutputGenerator(customizations)
    val httpResponseBindingErrorGenerator = HTTPResponseBindingErrorGenerator(customizations)
    val httpResponseBindingErrorInitGenerator = HTTPResponseBindingErrorInitGenerator(customizations)

    fun render(ctx: ProtocolGenerator.GenerationContext, httpOperations: List<OperationShape>, httpBindingResolver: HttpBindingResolver) {
        val visitedOutputShapes: MutableSet<ShapeId> = mutableSetOf()
        for (operation in httpOperations) {
            if (operation.output.isPresent) {
                val outputShapeId = operation.output.get()
                if (visitedOutputShapes.contains(outputShapeId)) {
                    continue
                }
                httpResponseBindingOutputGenerator.render(ctx, operation, httpBindingResolver, customizations.defaultTimestampFormat)
                visitedOutputShapes.add(outputShapeId)
            }
        }

        if (ctx.service.errors.isNotEmpty()) {
            httpResponseBindingErrorGenerator.renderServiceError(ctx)
        }
        httpOperations.forEach {
            httpResponseBindingErrorGenerator.renderOperationError(ctx, it, customizations.unknownServiceErrorSymbol)
        }

        val modeledOperationErrors = httpOperations
            .flatMap { it.errors }
            .map { ctx.model.expectShape(it) as StructureShape }
            .toSet()

        val modeledServiceErrors = ctx.service.errors
            .map { ctx.model.expectShape(it) as StructureShape }
            .toSet()

        val modeledErrors = modeledOperationErrors + modeledServiceErrors
        modeledErrors.forEach {
            httpResponseBindingErrorInitGenerator.render(ctx, it, httpBindingResolver)
        }
    }
}
