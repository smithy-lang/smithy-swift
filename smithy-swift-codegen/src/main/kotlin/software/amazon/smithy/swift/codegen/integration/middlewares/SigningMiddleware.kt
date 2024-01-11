package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep

class SigningMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider
) : MiddlewareRenderable {
    override val name = "SigningMiddleware"

    override val middlewareStep = MiddlewareStep.FINALIZESTEP

    override val position = MiddlewarePosition.BEFORE

    override fun render(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String
    ) {
        val output = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op)
        val outputError = MiddlewareShapeUtils.outputErrorSymbol(op)
        writer.write(
            "$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, middleware: \$N<\$N, \$N>())",
            ClientRuntimeTypes.Middleware.SigningMiddleware, output, outputError
        )
    }
}
