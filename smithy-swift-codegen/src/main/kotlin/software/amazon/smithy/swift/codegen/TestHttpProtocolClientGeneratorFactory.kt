package software.amazon.smithy.swift.codegen

import software.amazon.smithy.swift.codegen.integration.ClientProperty
import software.amazon.smithy.swift.codegen.integration.DefaultRequestEncoder
import software.amazon.smithy.swift.codegen.integration.DefaultResponseDecoder
import software.amazon.smithy.swift.codegen.integration.DefaultServiceConfig
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.HttpProtocolClientGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolClientGeneratorFactory
import software.amazon.smithy.swift.codegen.integration.HttpProtocolCustomizable
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.ServiceConfig
import software.amazon.smithy.swift.codegen.middleware.OperationMiddleware

class TestHttpProtocolClientGeneratorFactory : HttpProtocolClientGeneratorFactory {
    override fun createHttpProtocolClientGenerator(
        ctx: ProtocolGenerator.GenerationContext,
        httpBindingResolver: HttpBindingResolver,
        writer: SwiftWriter,
        serviceName: String,
        defaultContentType: String,
        httpProtocolCustomizable: HttpProtocolCustomizable,
        operationMiddleware: OperationMiddleware,
    ): HttpProtocolClientGenerator {
        val serviceSymbol = ctx.symbolProvider.toSymbol(ctx.service)
        val config = getConfigClass(writer, serviceSymbol.name)
        return HttpProtocolClientGenerator(
            ctx,
            writer,
            config,
            httpBindingResolver,
            defaultContentType,
            httpProtocolCustomizable,
            operationMiddleware
        )
    }

    private fun getClientProperties(ctx: ProtocolGenerator.GenerationContext): List<ClientProperty> {
        return mutableListOf(
            DefaultRequestEncoder(),
            DefaultResponseDecoder()
        )
    }

    private fun getConfigClass(writer: SwiftWriter, serviceName: String): ServiceConfig {
        return DefaultServiceConfig(writer, serviceName)
    }
}