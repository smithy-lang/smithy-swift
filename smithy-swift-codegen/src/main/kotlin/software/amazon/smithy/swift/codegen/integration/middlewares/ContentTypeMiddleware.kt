package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.ServiceGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep

class ContentTypeMiddleware(val defaultContentType: String) : MiddlewareRenderable {

    override val name = "ContentTypeMiddleware"

    override val middlewareStep = MiddlewareStep.SERIALIZESTEP

    override val position = MiddlewarePosition.AFTER

    override fun render(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        serviceShape: ServiceShape,
        op: OperationShape,
        operationStackName: String
    ) {
        val inputShapeName = ServiceGenerator.getOperationInputShapeName(ctx.symbolProvider, ctx.model, op)
        val outputShapeName = ServiceGenerator.getOperationOutputShapeName(ctx.symbolProvider, ctx.model, op)
        val outputErrorName = ServiceGenerator.getOperationErrorShapeName(op)
        writer.write("$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, middleware: ContentTypeMiddleware<$inputShapeName, $outputShapeName, $outputErrorName>(contentType: \"${defaultContentType}\"))")
    }
}
