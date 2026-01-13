package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.middleware.OperationMiddleware

class SmithyHttpProtocolClientGeneratorFactory : HttpProtocolClientGeneratorFactory {
    override fun createHttpProtocolClientGenerator(
        ctx: ProtocolGenerator.GenerationContext,
        configuratorSymbol: Symbol,
        httpBindingResolver: HttpBindingResolver,
        writer: SwiftWriter,
        serviceName: String,
        defaultContentType: String,
        httpProtocolCustomizable: HTTPProtocolCustomizable,
        operationMiddleware: OperationMiddleware,
    ): HttpProtocolClientGenerator {
        val config = SmithyServiceConfig(writer, ctx)
        return HttpProtocolClientGenerator(
            ctx,
            writer,
            configuratorSymbol,
            config,
            httpBindingResolver,
            defaultContentType,
            httpProtocolCustomizable,
            operationMiddleware,
        )
    }
}
