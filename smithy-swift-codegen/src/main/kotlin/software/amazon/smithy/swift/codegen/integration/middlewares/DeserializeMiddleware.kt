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

class DeserializeMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider
) : MiddlewareRenderable {

    override val name = "DeserializeMiddleware"

    override val middlewareStep = MiddlewareStep.DESERIALIZESTEP

    override val position = MiddlewarePosition.AFTER

    override fun render(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String
    ) {
        val output = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op)
        val outputBinding = ""
        val outputErrorBinding = ""
        writer.write(
            "\$L.\$L.intercept(position: \$L, middleware: \$N<\$N>(outputBinding: \$L, outputErrorBinding: \$L))",
            operationStackName,
            middlewareStep.stringValue(),
            position.stringValue(),
            ClientRuntimeTypes.Middleware.DeserializeMiddleware,
            output,
            outputBinding,
            outputErrorBinding
        )
    }
}
