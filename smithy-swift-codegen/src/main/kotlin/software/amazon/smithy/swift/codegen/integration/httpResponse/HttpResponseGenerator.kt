/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class HttpResponseGenerator(
    val unknownServiceErrorSymbol: Symbol,
    val defaultTimestampFormat: TimestampFormatTrait.Format,
    val httpResponseBindingOutputGenerator: HttpResponseBindingOutputGeneratable,
    val httpResponseBindingErrorGenerator: HttpResponseBindingErrorGeneratable,
    val httpResponseBindingErrorInitGeneratorFactory: HttpResponseBindingErrorInitGeneratorFactory? = null
) : HttpResponseGeneratable {

    override fun render(ctx: ProtocolGenerator.GenerationContext, httpOperations: List<OperationShape>, httpBindingResolver: HttpBindingResolver) {
        val visitedOutputShapes: MutableSet<ShapeId> = mutableSetOf()
        for (operation in httpOperations) {
            if (operation.output.isPresent) {
                val outputShapeId = operation.output.get()
                if (visitedOutputShapes.contains(outputShapeId)) {
                    continue
                }
                httpResponseBindingOutputGenerator.render(ctx, operation, httpBindingResolver, defaultTimestampFormat)
                visitedOutputShapes.add(outputShapeId)
            }
        }

        if (ctx.service.errors.isNotEmpty()) {
            httpResponseBindingErrorGenerator.renderServiceError(ctx)
        }
        httpOperations.forEach {
            httpResponseBindingErrorGenerator.renderOperationError(ctx, it, unknownServiceErrorSymbol)
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
            httpResponseBindingErrorInitGenerator(ctx, it, httpBindingResolver, defaultTimestampFormat)
        }
    }

    fun httpResponseBindingErrorInitGenerator(
        ctx: ProtocolGenerator.GenerationContext,
        structureShape: StructureShape,
        httpBindingResolver: HttpBindingResolver,
        defaultTimestampFormat: TimestampFormatTrait.Format
    ) {
        val httpResponseBindingErrorInitGenerator = httpResponseBindingErrorInitGeneratorFactory?.let {
            it.construct(ctx, structureShape, httpBindingResolver, defaultTimestampFormat)
        } ?: run {
            HttpResponseBindingErrorInitGenerator(ctx, structureShape, httpBindingResolver, defaultTimestampFormat)
        }
        httpResponseBindingErrorInitGenerator.render()
    }
}
