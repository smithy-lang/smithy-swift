package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class HttpResponseGenerator(
    val errorFromHttpResponseGenerator: HttpResponseBindingErrorGeneratable,
    val serviceErrorProtocolSymbol: Symbol,
    val unknownServiceErrorSymbol: Symbol,
    val defaultTimestampFormat: TimestampFormatTrait.Format,
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
                HttpResponseBindingOutputGenerator(ctx, operation, httpBindingResolver, defaultTimestampFormat).render()
                visitedOutputShapes.add(outputShapeId)
            }
        }

        httpOperations.forEach {
            errorFromHttpResponseGenerator.renderHttpResponseBinding(ctx, it)
            HttpResponseBindingErrorNarrowGenerator(ctx, it, unknownServiceErrorSymbol).render()
        }

        val modeledErrors = httpOperations.flatMap { it.errors }.map { ctx.model.expectShape(it) as StructureShape }.toSet()
        modeledErrors.forEach {
            httpResponseBindingErrorInitGenerator(ctx, it, httpBindingResolver, serviceErrorProtocolSymbol, defaultTimestampFormat)
        }
    }

    fun httpResponseBindingErrorInitGenerator(
        ctx: ProtocolGenerator.GenerationContext,
        structureShape: StructureShape,
        httpBindingResolver: HttpBindingResolver,
        serviceErrorProtocolSymbol: Symbol,
        defaultTimestampFormat: TimestampFormatTrait.Format
    ) {
        val httpResponseBindingErrorInitGenerator = httpResponseBindingErrorInitGeneratorFactory?.let {
            it.construct(ctx, structureShape, httpBindingResolver, serviceErrorProtocolSymbol, defaultTimestampFormat)
        } ?: run {
            HttpResponseBindingErrorInitGenerator(ctx, structureShape, httpBindingResolver, serviceErrorProtocolSymbol, defaultTimestampFormat)
        }
        httpResponseBindingErrorInitGenerator.render()
    }
}
