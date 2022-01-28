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

class OperationInputBodyMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider,
    val alwaysSendBody: Boolean = false
) : MiddlewareRenderable {

    override val name = "OperationInputBodyMiddleware"

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
        val hasHttpBody = MiddlewareShapeUtils.hasHttpBody(model, op)
        if (hasHttpBody || alwaysSendBody) {

            val alwaysSendBodyParam = if (alwaysSendBody) "alwaysSendBody: true" else ""
            val middlewareTypeName = if (MiddlewareShapeUtils.bodyIsHttpPayload(model, op)) "${inputShapeName}BodyMiddleware()" else "${ClientRuntimeTypes.Middleware.SerializableBodyMiddleware.fullName}<$inputShapeName, $outputShapeName, $errorShapeName>($alwaysSendBodyParam)"

            writer.write("$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, middleware: $middlewareTypeName)")
        }
    }
}
