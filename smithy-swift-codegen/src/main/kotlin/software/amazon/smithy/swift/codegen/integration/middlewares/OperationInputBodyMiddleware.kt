package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.ServiceGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.isInHttpBody
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep

class OperationInputBodyMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider,
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
        val inputShape = model.expectShape(op.input.get())
        val inputShapeName = ServiceGenerator.getOperationInputShapeName(symbolProvider, model, op)
        val hasHttpBody = inputShape.members().filter { it.isInHttpBody() }.count() > 0
        if (hasHttpBody || shouldRender) {
            writer.write("$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, middleware: ${inputShapeName}BodyMiddleware())")
        }
    }
}
