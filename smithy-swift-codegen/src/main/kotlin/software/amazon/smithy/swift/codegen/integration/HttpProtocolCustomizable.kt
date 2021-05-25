package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.protocoltests.traits.HttpRequestTestCase
import software.amazon.smithy.swift.codegen.SwiftWriter

open class HttpProtocolCustomizable {
    open fun renderMiddlewares(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape, operationStackName: String) {
        val middlewares = getHttpMiddlewares(ctx)
        for (middleware in middlewares) {
            middleware.renderMiddleware(ctx, writer, ctx.service, op, operationStackName)
        }
    }

    open fun renderInternals(ctx: ProtocolGenerator.GenerationContext) {
        // Default implementation is no-op
    }

    open fun renderMiddlewareForGeneratedRequestTests(
        writer: SwiftWriter,
        test: HttpRequestTestCase,
        operationStack: String,
        inputSymbol: Symbol,
        outputSymbol: Symbol,
        outputErrorName: String,
        hasHttpBody: Boolean
    ) {
        // Default implementation is no-op
    }

    open fun renderContextAttributes(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        serviceShape: ServiceShape,
        op: OperationShape
    ) {
        // Default implementation is no-op
    }

    open fun getClientProperties(ctx: ProtocolGenerator.GenerationContext): List<ClientProperty> {
        return emptyList()
    }

    /**
     * Get all of the middleware that should be installed into the operation's middleware stack (`SdkOperationExecution`)
     * This is the function that protocol client generators should invoke to get the fully resolved set of middleware
     * to be rendered (i.e. after integrations have had a chance to intercept). The default set of middleware for
     * a protocol can be overridden by [getDefaultHttpMiddleware].
     */
    fun getHttpMiddlewares(ctx: ProtocolGenerator.GenerationContext): List<ProtocolMiddleware> {
        val defaultMiddleware = getDefaultProtocolMiddlewares(ctx)
        return ctx.integrations.fold(defaultMiddleware) { middleware, integration ->
            integration.customizeMiddleware(ctx, middleware)
        }
    }


    protected open fun getDefaultProtocolMiddlewares(ctx: ProtocolGenerator.GenerationContext): List<ProtocolMiddleware> {
        return emptyList()
    }
}
