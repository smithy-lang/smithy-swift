package software.amazon.smithy.swift.codegen.integration.middlewares.handlers

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.HttpTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes.Core.ClientError
import software.amazon.smithy.swift.codegen.Middleware
import software.amazon.smithy.swift.codegen.MiddlewareGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.steps.OperationInitializeStep
import software.amazon.smithy.swift.codegen.model.isBoxed
import software.amazon.smithy.swift.codegen.model.toMemberNames

class HttpUrlPathMiddleware(
    private val ctx: ProtocolGenerator.GenerationContext,
    inputSymbol: Symbol,
    outputSymbol: Symbol,
    outputErrorSymbol: Symbol,
    private val httpTrait: HttpTrait,
    private val pathBindings: List<HttpBindingDescriptor>,
    private val writer: SwiftWriter
) : Middleware(writer, inputSymbol, OperationInitializeStep(inputSymbol, outputSymbol, outputErrorSymbol)) {

    companion object {
        fun renderUrlPathMiddleware(ctx: ProtocolGenerator.GenerationContext, op: OperationShape, httpBindingResolver: HttpBindingResolver) {
            val httpTrait = httpBindingResolver.httpTrait(op)
            val requestBindings = httpBindingResolver.requestBindings(op)
            val pathBindings = requestBindings.filter { it.location == HttpBinding.Location.LABEL }

            val inputSymbol = MiddlewareHandlerUtils.inputSymbol(ctx, op)
            val outputSymbol = MiddlewareHandlerUtils.outputSymbol(ctx, op)
            val outputErrorSymbol = MiddlewareHandlerUtils.outputErrorSymbol(op)
            val rootNamespace = MiddlewareHandlerUtils.rootNamespace(ctx)

            val urlPathMiddlewareSymbol = Symbol.builder()
                .definitionFile("./$rootNamespace/models/${inputSymbol.name}+UrlPathMiddleware.swift")
                .name(inputSymbol.name)
                .build()
            ctx.delegator.useShapeWriter(urlPathMiddlewareSymbol) { writer ->
                writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                val urlPathMiddleware = HttpUrlPathMiddleware(ctx, inputSymbol, outputSymbol, outputErrorSymbol, httpTrait, pathBindings, writer)
                MiddlewareGenerator(writer, urlPathMiddleware).generate()
            }
        }
    }

    override val typeName = "${inputSymbol.name}URLPathMiddleware"

    override fun generateMiddlewareClosure() {
        renderUriPath()
    }

    override fun generateInit() {
        writer.write("let urlPrefix: \$T", SwiftTypes.String)
        writer.write("")
        writer.openBlock("public init(urlPrefix: \$T = nil) {", "}", SwiftTypes.String) {
            writer.write("self.urlPrefix = urlPrefix")
        }
    }

    override fun renderReturn() {
        writer.write("return next.handle(context: copiedContext, input: input)")
    }

    private fun renderUriPath() {
        val resolvedURIComponents = mutableListOf<String>()
        httpTrait.uri.segments.forEach {
            if (it.isLabel) {
                // spec dictates member name and label name MUST be the same
                val binding = pathBindings.find { binding ->
                    binding.memberName == it.content
                } ?: throw CodegenException("failed to find corresponding member for httpLabel `${it.content}")

                // shape must be string, number, boolean, or timestamp
                val targetShape = ctx.model.expectShape(binding.member.target)
                val labelMemberName = ctx.symbolProvider.toMemberNames(binding.member).first.decapitalize()
                val formattedLabel: String = when (targetShape.type) {
                    ShapeType.TIMESTAMP -> {
                        val bindingIndex = HttpBindingIndex.of(ctx.model)
                        val timestampFormat = bindingIndex.determineTimestampFormat(
                            binding.member,
                            HttpBinding.Location.LABEL,
                            TimestampFormatTrait.Format.DATE_TIME
                        )
                        ProtocolGenerator.getFormattedDateString(
                            timestampFormat,
                            labelMemberName,
                            roundEpoch = true,
                            urlEncode = true
                        )
                    }
                    ShapeType.STRING -> {
                        val percentEncoded = if (!it.isGreedyLabel) ".urlPercentEncoding()" else ""
                        val enumRawValueSuffix =
                            targetShape.getTrait(EnumTrait::class.java).map { ".rawValue" }.orElse("")
                        "$labelMemberName$enumRawValueSuffix$percentEncoded"
                    }
                    ShapeType.FLOAT, ShapeType.DOUBLE -> "$labelMemberName.encoded()"
                    else -> labelMemberName
                }
                val isBoxed = ctx.symbolProvider.toSymbol(targetShape).isBoxed()

                // unwrap the label members if boxed
                if (isBoxed) {
                    writer.openBlock("guard let $labelMemberName = input.$labelMemberName else {", "}") {
                        writer.write("return .failure(.client(\$N.pathCreationFailed((\"$labelMemberName is nil and needs a value for the path of this operation\"))))", ClientError)
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
        writer.write("var urlPath = \"\$L\"", uri)
        writer.openBlock("if let urlPrefix = urlPrefix, !urlPrefix.isEmpty {", "}") {
            writer.write("urlPath = \"\\(urlPrefix)\\(urlPath)\"")
        }
        writer.write("var copiedContext = context")
        writer.write("copiedContext.attributes.set(key: AttributeKey<String>(name: \"Path\"), value: urlPath)")
    }
}
