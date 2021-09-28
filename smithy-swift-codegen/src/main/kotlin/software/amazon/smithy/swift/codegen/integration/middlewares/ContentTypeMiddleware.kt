package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.ServiceGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep

class ContentTypeMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider,
    val defaultContentType: String
) : MiddlewareRenderable {

    override val name = "ContentTypeMiddleware"

    override val middlewareStep = MiddlewareStep.SERIALIZESTEP

    override val position = MiddlewarePosition.AFTER

    override fun render(
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String,
    ) {
        val inputShapeName = ServiceGenerator.getOperationInputShapeName(symbolProvider, model, op)
        val outputShapeName = ServiceGenerator.getOperationOutputShapeName(symbolProvider, model, op)
        val outputErrorName = ServiceGenerator.getOperationErrorShapeName(op)
        writer.write("$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, middleware: ContentTypeMiddleware<$inputShapeName, $outputShapeName, $outputErrorName>(contentType: \"${defaultContentType}\"))")
    }
}
