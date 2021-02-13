package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.swift.codegen.SwiftWriter

interface HttpProtocolClientGeneratorFactory {
    fun createHttpProtocolClientGenerator(ctx: ProtocolGenerator.GenerationContext, httpBindingResolver: HttpBindingResolver, writer: SwiftWriter, serviceName: String, defaultContentType: String): HttpProtocolClientGenerator
}
