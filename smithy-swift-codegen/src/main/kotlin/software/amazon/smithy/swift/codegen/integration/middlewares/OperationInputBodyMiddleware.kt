package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.XmlNameTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep
import software.amazon.smithy.swift.codegen.model.getTrait

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
        val inputShape = MiddlewareShapeUtils.inputShape(model, op)
        val inputShapeName = MiddlewareShapeUtils.inputSymbol(symbolProvider, model, op).name
        val outputShapeName = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op).name
        val xmlName = inputShape.getTrait<XmlNameTrait>()?.value

        if (alwaysSendBody) {
            if (xmlName != null) {
                writer.write(
                    "\$L.\$L.intercept(position: \$L, middleware: \$N<\$L, \$L>(xmlName: \"\$L\"))",
                    operationStackName, middlewareStep.stringValue(), position.stringValue(), ClientRuntimeTypes.Middleware.SerializableBodyMiddleware, inputShapeName, outputShapeName, xmlName
                )
            } else {
                writer.write(
                    "\$L.\$L.intercept(position: \$L, middleware: \$N<\$L, \$L>())",
                    operationStackName, middlewareStep.stringValue(), position.stringValue(), ClientRuntimeTypes.Middleware.SerializableBodyMiddleware, inputShapeName, outputShapeName
                )
            }
        } else if (MiddlewareShapeUtils.hasHttpBody(model, op)) {
            if (MiddlewareShapeUtils.bodyIsHttpPayload(model, op)) {
                writer.write("$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, middleware: ${inputShapeName}BodyMiddleware())")
            } else {
                if (xmlName != null) {
                    writer.write(
                        "\$L.\$L.intercept(position: \$L, middleware: \$N<\$L, \$L>(xmlName: \"\$L\"))",
                        operationStackName, middlewareStep.stringValue(), position.stringValue(), ClientRuntimeTypes.Middleware.SerializableBodyMiddleware, inputShapeName, outputShapeName, xmlName
                    )
                } else {
                    writer.write(
                        "\$L.\$L.intercept(position: \$L, middleware: \$N<\$L, \$L>())",
                        operationStackName, middlewareStep.stringValue(), position.stringValue(), ClientRuntimeTypes.Middleware.SerializableBodyMiddleware, inputShapeName, outputShapeName
                    )
                }
            }
        }
    }
}
