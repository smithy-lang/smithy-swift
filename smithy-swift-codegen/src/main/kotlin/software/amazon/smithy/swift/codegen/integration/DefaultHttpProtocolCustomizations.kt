package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.middlewares.LoggingMiddleware

abstract class DefaultHttpProtocolCustomizations : HttpProtocolCustomizable {
    override fun renderMiddlewares(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String
    ) {
        val middlewares = operationMiddlewares(ctx)
        for (middleware in middlewares) {
            middleware.render(ctx, writer, ctx.service, op, operationStackName)
        }
    }

    override fun operationMiddlewares(ctx: ProtocolGenerator.GenerationContext): List<OperationMiddlewareRenderable> {
        val defaultMiddleware = baseMiddlewares(ctx)
        return ctx.integrations.fold(defaultMiddleware) { middleware, integration ->
            integration.customizeMiddleware(ctx, middleware)
        }
    }
    override fun baseMiddlewares(ctx: ProtocolGenerator.GenerationContext): List<OperationMiddlewareRenderable> {
        return listOf(LoggingMiddleware())
    }
}
