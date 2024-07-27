package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes

class ContentLengthMiddleware(
    val model: Model,
    private val alwaysIntercept: Boolean,
    private val requiresLength: Boolean,
    private val unsignedPayload: Boolean
) : MiddlewareRenderable {

    override val name = "ContentLengthMiddleware"

    override fun render(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String,
    ) {
        val hasHttpBody = MiddlewareShapeUtils.hasHttpBody(model, op)
        if (hasHttpBody || alwaysIntercept) {
            super.render(ctx, writer, op, operationStackName)
        }
    }

    override fun renderMiddlewareInit(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape
    ) {
        val str = "requiresLength: $requiresLength, unsignedPayload: $unsignedPayload"
        val middlewareArgs = str.takeIf { requiresLength || unsignedPayload } ?: ""

        val inputShapeName = MiddlewareShapeUtils.inputSymbol(ctx.symbolProvider, model, op).name
        val outputShapeName = MiddlewareShapeUtils.outputSymbol(ctx.symbolProvider, model, op).name
        writer.write("\$N<$inputShapeName, $outputShapeName>($middlewareArgs)", ClientRuntimeTypes.Middleware.ContentLengthMiddleware)
    }
}
