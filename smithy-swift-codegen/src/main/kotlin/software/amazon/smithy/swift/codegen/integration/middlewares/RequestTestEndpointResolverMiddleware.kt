package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep

class RequestTestEndpointResolverMiddleware(private val model: Model, private val symbolProvider: SymbolProvider) : MiddlewareRenderable {
    override val name = "RequestTestEndpointResolver"
    override val middlewareStep = MiddlewareStep.BUILDSTEP
    override val position = MiddlewarePosition.AFTER
    override fun render(writer: SwiftWriter, op: OperationShape, operationStackName: String) {

        val outputShapeName = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op).name
        val outputErrorShapeName = MiddlewareShapeUtils.outputErrorSymbolName(op)
        writer.openBlock(
            "$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, id: \"${name}\") { (context, input, next) -> \$N<\$N<$outputShapeName>, \$N<$outputErrorShapeName>> in", "}",
            SwiftTypes.Result,
            ClientRuntimeTypes.Middleware.OperationOutput,
            ClientRuntimeTypes.Core.SdkError
        ) {
            writer.write("input.withMethod(context.getMethod())")
            writer.write("input.withPath(context.getPath())")
            writer.write("let host = \"\\(context.getHostPrefix() ?? \"\")\\(context.getHost() ?? \"\")\"")
            writer.write("input.withHost(host)")
            writer.write("return next.handle(context: context, input: input)")
        }
    }
}
