package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep

class ContentLengthMiddleware(val model: Model, private val alwaysIntercept: Boolean) : MiddlewareRenderable {

    override val name = "ContentLengthMiddleware"

    override val middlewareStep = MiddlewareStep.FINALIZESTEP

    override val position = MiddlewarePosition.BEFORE

    override fun render(
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String
    ) {
        val hasHttpBody = MiddlewareShapeUtils.hasHttpBody(model, op)
        if (hasHttpBody || alwaysIntercept) {
            writer.write(
                "\$L.\$L.intercept(position: \$L, middleware: \$N())",
                operationStackName,
                middlewareStep.stringValue(),
                position.stringValue(),
                ClientRuntimeTypes.Middleware.ContentLengthMiddleware
            )
        }
    }
}
