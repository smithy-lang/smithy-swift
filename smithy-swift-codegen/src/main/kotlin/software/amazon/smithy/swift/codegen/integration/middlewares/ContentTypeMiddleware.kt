package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep

class ContentTypeMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider,
    val defaultContentType: String,
    val shouldRender: Boolean = false
) : MiddlewareRenderable {

    override val name = "ContentTypeMiddleware"

    override val middlewareStep = MiddlewareStep.SERIALIZESTEP

    override val position = MiddlewarePosition.AFTER

    override fun render(
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String,
    ) {
        val hasHttpBody = MiddlewareShapeUtils.hasHttpBody(model, op)
        if (hasHttpBody || shouldRender) {
            val inputShapeName = MiddlewareShapeUtils.inputSymbol(symbolProvider, model, op).name
            val outputShapeName = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op).name
            val outputErrorName = MiddlewareShapeUtils.outputErrorSymbolName(op)
            writer.write("$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, middleware: ContentTypeMiddleware<$inputShapeName, $outputShapeName, $outputErrorName>(contentType: \"${defaultContentType}\"))")
        }
    }
}
