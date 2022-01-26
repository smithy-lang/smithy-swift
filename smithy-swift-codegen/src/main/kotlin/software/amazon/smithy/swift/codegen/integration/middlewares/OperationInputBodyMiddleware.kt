package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep

class OperationInputBodyMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider,
    val httpBindingResolver: HttpBindingResolver,
    val shouldRender: Boolean = false
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
        if (hasHttpBody || shouldRender) {
            val requestBindings = httpBindingResolver.requestBindings(op)
            val middlewareTypeName = if (requestBindings.firstOrNull { it.location == HttpBinding.Location.PAYLOAD } != null) "${inputShapeName}BodyMiddleware" else "ClientRuntime.SerializableBodyMiddleware<$inputShapeName, $outputShapeName, $errorShapeName>"
            writer.write("$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, middleware: $middlewareTypeName())")
        }
    }
}
