package software.amazon.smithy.swift.codegen.middleware

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes.Middleware.OperationStack
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.HttpProtocolCustomizable
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.model.camelCaseName
import software.amazon.smithy.swift.codegen.model.capitalizedName
import software.amazon.smithy.swift.codegen.swiftFunctionParameterIndent

typealias HttpMethodCallback = (OperationShape) -> String
class MiddlewareExecutionGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val httpBindingResolver: HttpBindingResolver,
    private val httpProtocolCustomizable: HttpProtocolCustomizable,
    private val operationMiddleware: OperationMiddleware,
    private val operationStackName: String,
    private val httpMethodCallback: HttpMethodCallback? = null
) {
    private val model: Model = ctx.model
    private val symbolProvider = ctx.symbolProvider

    fun render(op: OperationShape, onError: (SwiftWriter, String) -> Unit) {
        val operationErrorName = "${op.capitalizedName()}OutputError"
        val inputShapeName = MiddlewareShapeUtils.inputSymbol(symbolProvider, ctx.model, op).name
        val outputShapeName = MiddlewareShapeUtils.outputSymbol(symbolProvider, ctx.model, op).name
        writer.write("let context = \$N()", ClientRuntimeTypes.Http.HttpContextBuilder)
        writer.swiftFunctionParameterIndent {
            renderContextAttributes(op)
        }
        writer.write("var $operationStackName = \$N<$inputShapeName, $outputShapeName, $operationErrorName>(id: \"${op.camelCaseName()}\")", OperationStack)
        renderMiddlewares(op, operationStackName)
    }

    private fun renderContextAttributes(op: OperationShape) {
        val httpMethod = resolveHttpMethod(op)

        // FIXME it over indents if i add another indent, come up with better way to properly indent or format for swift
        writer.write("  .withEncoder(value: encoder)")
        writer.write("  .withDecoder(value: decoder)")
        writer.write("  .withMethod(value: .$httpMethod)")
        writer.write("  .withServiceName(value: serviceName)")
        writer.write("  .withOperation(value: \"${op.camelCaseName()}\")")
        writer.write("  .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)")
        writer.write("  .withLogger(value: config.logger)")

        val serviceShape = ctx.service
        httpProtocolCustomizable.renderContextAttributes(ctx, writer, serviceShape, op)
    }

    private fun resolveHttpMethod(op: OperationShape): String {
        return httpMethodCallback?.let {
            it(op)
        } ?: run {
            val httpTrait = httpBindingResolver.httpTrait(op)
            httpTrait.method.toLowerCase()
        }
    }

    private fun renderMiddlewares(op: OperationShape, operationStackName: String) {
        operationMiddleware.renderMiddleware(writer, op, operationStackName, MiddlewareStep.INITIALIZESTEP)
        operationMiddleware.renderMiddleware(writer, op, operationStackName, MiddlewareStep.BUILDSTEP)
        operationMiddleware.renderMiddleware(writer, op, operationStackName, MiddlewareStep.SERIALIZESTEP)
        operationMiddleware.renderMiddleware(writer, op, operationStackName, MiddlewareStep.FINALIZESTEP)
        operationMiddleware.renderMiddleware(writer, op, operationStackName, MiddlewareStep.DESERIALIZESTEP)
    }
}
