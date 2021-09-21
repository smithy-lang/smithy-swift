package software.amazon.smithy.swift.codegen.middleware

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.EndpointTrait
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.HttpTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes.Middleware.OperationStack
import software.amazon.smithy.swift.codegen.ServiceGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.EndpointTraitConstructor
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.HttpProtocolCustomizable
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.camelCaseName
import software.amazon.smithy.swift.codegen.model.capitalizedName
import software.amazon.smithy.swift.codegen.model.isBoxed
import software.amazon.smithy.swift.codegen.model.toMemberNames
import software.amazon.smithy.swift.codegen.swiftFunctionParameterIndent

class MiddlewareExecutionGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val httpBindingResolver: HttpBindingResolver,
    private val httpProtocolCustomizable: HttpProtocolCustomizable,
    private val operationMiddleware: OperationMiddleware,
    private val operationStackName: String,
    private val executionContext: MiddlewareRenderableExecutionContext
) {
    private val model: Model = ctx.model
    private val symbolProvider = ctx.symbolProvider

    fun render(op: OperationShape, onError: (SwiftWriter, String) -> Unit) {
        val httpTrait = httpBindingResolver.httpTrait(op)
        val requestBindings = httpBindingResolver.requestBindings(op)
        val pathBindings = requestBindings.filter { it.location == HttpBinding.Location.LABEL }
        renderUriPath(httpTrait, pathBindings, writer, onError)

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

    // replace labels with any path bindings
    private fun renderUriPath(httpTrait: HttpTrait, pathBindings: List<HttpBindingDescriptor>, writer: SwiftWriter, onError: (SwiftWriter, String) -> Unit) {
        val resolvedURIComponents = mutableListOf<String>()
        httpTrait.uri.segments.forEach {
            if (it.isLabel) {
                // spec dictates member name and label name MUST be the same
                val binding = pathBindings.find { binding ->
                    binding.memberName == it.content
                } ?: throw CodegenException("failed to find corresponding member for httpLabel `${it.content}")

                // shape must be string, number, boolean, or timestamp
                val targetShape = model.expectShape(binding.member.target)
                val labelMemberName = ctx.symbolProvider.toMemberNames(binding.member).first.decapitalize()
                val formattedLabel: String
                if (targetShape.isTimestampShape) {
                    val bindingIndex = HttpBindingIndex.of(model)
                    val timestampFormat = bindingIndex.determineTimestampFormat(targetShape, HttpBinding.Location.LABEL, TimestampFormatTrait.Format.DATE_TIME)
                    formattedLabel = ProtocolGenerator.getFormattedDateString(timestampFormat, labelMemberName)
                } else if (targetShape.isStringShape) {
                    val enumRawValueSuffix = targetShape.getTrait(EnumTrait::class.java).map { ".rawValue" }.orElse("")
                    formattedLabel = "$labelMemberName$enumRawValueSuffix"
                } else {
                    formattedLabel = labelMemberName
                }
                val isBoxed = symbolProvider.toSymbol(targetShape).isBoxed()

                // unwrap the label members if boxed
                if (isBoxed) {
                    writer.openBlock("guard let $labelMemberName = input.$labelMemberName else {", "}") {
                        onError(writer, labelMemberName)
                    }
                } else {
                    writer.write("let $labelMemberName = input.$labelMemberName")
                }
                resolvedURIComponents.add("\\($formattedLabel)")
            } else {
                resolvedURIComponents.add(it.content)
            }
        }

        val uri = resolvedURIComponents.joinToString(separator = "/", prefix = "/", postfix = "")
        writer.write("let urlPath = \"\$L\"", uri)
    }

    private fun renderContextAttributes(op: OperationShape) {
        val httpTrait = httpBindingResolver.httpTrait(op)
        val httpMethod = httpTrait.method.toLowerCase()
        // FIXME it over indents if i add another indent, come up with better way to properly indent or format for swift
        writer.write("  .withEncoder(value: encoder)")
        writer.write("  .withDecoder(value: decoder)")
        writer.write("  .withMethod(value: .$httpMethod)")
        writer.write("  .withPath(value: urlPath)")
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

    private fun renderMiddlewares(op: OperationShape, operationStackName: String) {
        operationMiddleware.renderMiddleware(ctx.model, ctx.symbolProvider, writer, op, operationStackName, MiddlewareStep.INITIALIZESTEP, executionContext)
        operationMiddleware.renderMiddleware(ctx.model, ctx.symbolProvider, writer, op, operationStackName, MiddlewareStep.BUILDSTEP, executionContext)
        operationMiddleware.renderMiddleware(ctx.model, ctx.symbolProvider, writer, op, operationStackName, MiddlewareStep.SERIALIZESTEP, executionContext)
        operationMiddleware.renderMiddleware(ctx.model, ctx.symbolProvider, writer, op, operationStackName, MiddlewareStep.FINALIZESTEP, executionContext)
        operationMiddleware.renderMiddleware(ctx.model, ctx.symbolProvider, writer, op, operationStackName, MiddlewareStep.DESERIALIZESTEP, executionContext)
    }
}
