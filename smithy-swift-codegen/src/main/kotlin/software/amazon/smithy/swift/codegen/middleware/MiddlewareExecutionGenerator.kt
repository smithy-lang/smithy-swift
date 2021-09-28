package software.amazon.smithy.swift.codegen.middleware

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.EndpointTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes.Middleware.OperationStack
import software.amazon.smithy.swift.codegen.ServiceGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.EndpointTraitConstructor
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.HttpProtocolCustomizable
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.camelCaseName
import software.amazon.smithy.swift.codegen.model.capitalizedName
import software.amazon.smithy.swift.codegen.swiftFunctionParameterIndent

typealias HttpMethodCallback = () -> String
class MiddlewareExecutionGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val httpBindingResolver: HttpBindingResolver,
    private val httpProtocolCustomizable: HttpProtocolCustomizable,
    private val operationMiddleware: OperationMiddleware,
    private val operationStackName: String,
    private val executionContext: MiddlewareRenderableExecutionContext,
    private val httpMethodCallback: HttpMethodCallback? = null
) {
    private val model: Model = ctx.model
    private val symbolProvider = ctx.symbolProvider

    fun render(op: OperationShape, onError: (SwiftWriter, String) -> Unit) {
        val operationErrorName = "${op.capitalizedName()}OutputError"
        val inputShapeName = ServiceGenerator.getOperationInputShapeName(symbolProvider, ctx.model, op)
        val outputShapeName = ServiceGenerator.getOperationOutputShapeName(symbolProvider, ctx.model, op)
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

        op.getTrait(EndpointTrait::class.java).ifPresent {
            val inputShape = model.expectShape(op.input.get())
            val hostPrefix = EndpointTraitConstructor(it, inputShape).construct()
            writer.write("  .withHostPrefix(value: \"\$L\")", hostPrefix)
        }
        val serviceShape = ctx.service
        httpProtocolCustomizable.renderContextAttributes(ctx, writer, serviceShape, op)
    }

    private fun resolveHttpMethod(op: OperationShape): String {
        return httpMethodCallback?.let {
            it()
        } ?: run {
            val httpTrait = httpBindingResolver.httpTrait(op)
            httpTrait.method.toLowerCase()
        }
    }

    private fun renderMiddlewares(op: OperationShape, operationStackName: String) {
        operationMiddleware.renderMiddleware(ctx.model, ctx.symbolProvider, writer, op, operationStackName, MiddlewareStep.INITIALIZESTEP, executionContext)
        operationMiddleware.renderMiddleware(ctx.model, ctx.symbolProvider, writer, op, operationStackName, MiddlewareStep.BUILDSTEP, executionContext)
        operationMiddleware.renderMiddleware(ctx.model, ctx.symbolProvider, writer, op, operationStackName, MiddlewareStep.SERIALIZESTEP, executionContext)
        operationMiddleware.renderMiddleware(ctx.model, ctx.symbolProvider, writer, op, operationStackName, MiddlewareStep.FINALIZESTEP, executionContext)
        operationMiddleware.renderMiddleware(ctx.model, ctx.symbolProvider, writer, op, operationStackName, MiddlewareStep.DESERIALIZESTEP, executionContext)
    }
}
