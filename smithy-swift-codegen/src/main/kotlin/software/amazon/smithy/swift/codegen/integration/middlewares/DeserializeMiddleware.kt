package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderableExecutionContext
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep

class DeserializeMiddleware : MiddlewareRenderable {

    override val name = "DeserializeMiddleware"

    override val middlewareStep = MiddlewareStep.DESERIALIZESTEP

    override val position = MiddlewarePosition.AFTER

    override fun render(
        model: Model,
        symbolProvider: SymbolProvider,
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String,
        executionContext: MiddlewareRenderableExecutionContext
    ) {
        writer.write("$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, middleware: \$N())", ClientRuntimeTypes.Middleware.DeserializeMiddleware)
    }
}
