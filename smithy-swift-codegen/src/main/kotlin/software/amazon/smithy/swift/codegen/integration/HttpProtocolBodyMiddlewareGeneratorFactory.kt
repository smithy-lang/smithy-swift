package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.Middleware
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.HttpBodyMiddleware

interface HttpProtocolBodyMiddlewareGeneratorFactory {
    fun shouldRenderHttpBodyMiddleware(shape: Shape): Boolean

    fun httpBodyMiddleware(
        writer: SwiftWriter,
        ctx: ProtocolGenerator.GenerationContext,
        inputSymbol: Symbol,
        outputSymbol: Symbol,
        outputErrorSymbol: Symbol,
        requestBindings: List<HttpBindingDescriptor>
    ): Middleware
}

class DefaultHttpProtocolBodyMiddlewareGeneratorFactory : HttpProtocolBodyMiddlewareGeneratorFactory {
    override fun shouldRenderHttpBodyMiddleware(shape: Shape): Boolean {
        return shape.members().any { it.isInHttpBody() }
    }

    override fun httpBodyMiddleware(
        writer: SwiftWriter,
        ctx: ProtocolGenerator.GenerationContext,
        inputSymbol: Symbol,
        outputSymbol: Symbol,
        outputErrorSymbol: Symbol,
        requestBindings: List<HttpBindingDescriptor>
    ): Middleware {
        return HttpBodyMiddleware(writer, ctx, inputSymbol, outputSymbol, outputErrorSymbol, requestBindings)
    }
}
