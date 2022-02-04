package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep

class OperationInputHeadersMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider
) : MiddlewareRenderable {

    override val name = "OperationInputHeadersMiddleware"

    override val middlewareStep = MiddlewareStep.SERIALIZESTEP

    override val position = MiddlewarePosition.AFTER

    override fun render(
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String,
    ) {
        val inputShapeName = MiddlewareShapeUtils.inputSymbol(symbolProvider, model, op).name
        val outputShapeName = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op).name
        val errorShapeName = MiddlewareShapeUtils.outputErrorSymbolName(op)
        val hasHeaders = MiddlewareShapeUtils.hasHttpHeaders(model, op)
        if (hasHeaders) {
            writer.write("$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, middleware: \$N<$inputShapeName, $outputShapeName, $errorShapeName>())", ClientRuntimeTypes.Middleware.HeaderMiddleware)
        }
    }
}
