package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes

class RequestTestEndpointResolverMiddleware(private val model: Model, private val symbolProvider: SymbolProvider) : MiddlewareRenderable {
    override val name = "RequestTestEndpointResolver"
    override val middlewareStep = MiddlewareStep.BUILDSTEP
    override val position = MiddlewarePosition.AFTER
    override fun render(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape, operationStackName: String) {

        val outputShapeName = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op).name
        val outputErrorShapeName = MiddlewareShapeUtils.outputErrorSymbolName(op)
        if (ctx.settings.useInterceptors) {
            writer.write(
                """
                builder.applyEndpoint({ (request, scheme, attributes) in
                    return request.toBuilder()
                        .withMethod(attributes.method)
                        .withPath(attributes.path)
                        .withHost("\(attributes.hostPrefix ?? "")\(attributes.host ?? "")")
                        .build()
                })
                """.trimMargin()
            )
        } else {
            writer.openBlock(
                "$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, id: \"${name}\") { (context, input, next) -> \$N<$outputShapeName> in", "}",
                ClientRuntimeTypes.Middleware.OperationOutput
            ) {
                writer.write("input.withMethod(context.method)")
                writer.write("input.withPath(context.path)")
                writer.write("let host = \"\\(context.hostPrefix ?? \"\")\\(context.host ?? \"\")\"")
                writer.write("input.withHost(host)")
                writer.write("return try await next.handle(context: context, input: input)")
            }
        }
    }
}
