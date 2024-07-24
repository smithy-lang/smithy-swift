package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes

class ContentTypeMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider,
    val defaultContentType: String,
    val shouldRender: Boolean = false
) : MiddlewareRenderable {

    override val name = "ContentTypeMiddleware"

    override fun render(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String,
    ) {
        val hasHttpBody = MiddlewareShapeUtils.hasHttpBody(model, op)
        if (hasHttpBody || shouldRender) {
            super.render(ctx, writer, op, operationStackName)
        }
    }

    override fun renderMiddlewareInit(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape
    ) {
        val inputShapeName = MiddlewareShapeUtils.inputSymbol(symbolProvider, model, op).name
        val outputShapeName = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op).name
        writer.write(
            "\$N<\$L, \$L>(contentType: \$S)",
            ClientRuntimeTypes.Middleware.ContentTypeMiddleware,
            inputShapeName,
            outputShapeName,
            defaultContentType,
        )
    }
}
