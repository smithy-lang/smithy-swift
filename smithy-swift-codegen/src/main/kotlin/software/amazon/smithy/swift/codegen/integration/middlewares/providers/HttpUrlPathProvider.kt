package software.amazon.smithy.swift.codegen.integration.middlewares.providers

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.HttpTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.model.isBoxed
import software.amazon.smithy.swift.codegen.model.toMemberNames
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes
import software.amazon.smithy.swift.codegen.utils.ModelFileUtils

class HttpUrlPathProvider(
    private val ctx: ProtocolGenerator.GenerationContext,
    val inputSymbol: Symbol,
    private val httpTrait: HttpTrait,
    private val pathBindings: List<HttpBindingDescriptor>,
    private val writer: SwiftWriter
) {
    companion object {
        fun renderUrlPathMiddleware(ctx: ProtocolGenerator.GenerationContext, op: OperationShape, httpBindingResolver: HttpBindingResolver) {
            val httpTrait = httpBindingResolver.httpTrait(op)
            val requestBindings = httpBindingResolver.requestBindings(op)
            val pathBindings = requestBindings.filter { it.location == HttpBinding.Location.LABEL }
            val inputSymbol = MiddlewareShapeUtils.inputSymbol(ctx.symbolProvider, ctx.model, op)
            val filename = ModelFileUtils.filename(ctx.settings, "${inputSymbol.name}+UrlPathProvider")
            val urlPathMiddlewareSymbol = Symbol.builder()
                .definitionFile(filename)
                .name(inputSymbol.name)
                .build()
            ctx.delegator.useShapeWriter(urlPathMiddlewareSymbol) { writer ->
                val urlPathMiddleware = HttpUrlPathProvider(ctx, inputSymbol, httpTrait, pathBindings, writer)
                urlPathMiddleware.renderProvider(writer)
            }
        }
    }

    fun renderProvider(writer: SwiftWriter) {
        writer.openBlock("extension \$N {", "}", inputSymbol) {
            writer.write("")
            writer.openBlock(
                "static func urlPathProvider(_ value: \$N) -> \$T {",
                "}",
                inputSymbol,
                SwiftTypes.String,
            ) {
                renderUriPath()
            }
        }
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
                            urlEncode = true
                        )
                    }
                    ShapeType.STRING -> {
                        val percentEncoded = urlEncoding(it.isGreedyLabel)
                        val enumRawValueSuffix =
                            targetShape.getTrait(EnumTrait::class.java).map { ".rawValue" }.orElse("")
                        "$labelMemberName$enumRawValueSuffix$percentEncoded"
                    }
                    ShapeType.FLOAT, ShapeType.DOUBLE -> "$labelMemberName.encoded()"
                    ShapeType.ENUM -> {
                        val percentEncoded = urlEncoding(it.isGreedyLabel)
                        "$labelMemberName.rawValue$percentEncoded"
                    }
                    else -> labelMemberName
                }

                // use member symbol to determine if we need to box the value
                // similar to how struct is generated
                val symbol = ctx.symbolProvider.toSymbol(binding.member)

                // unwrap the label members if boxed
                if (symbol.isBoxed()) {
                    writer.openBlock("guard let $labelMemberName = value.$labelMemberName else {", "}") {
                        writer.write("return nil")
                    }
                }
                resolvedURIComponents.add("\\($formattedLabel)")
            } else {
                resolvedURIComponents.add(it.content)
            }
        }

        val uri = resolvedURIComponents.joinToString(separator = "/", prefix = "/", postfix = "")
        writer.write("return \"\$L\"", uri)
    }

    /**
     * Provides the appropriate Swift method call for URL encoding a String path component.
     *
     * For non-greedy labels, forward-slash is encoded because the label must fill in
     * exactly one path component.
     *
     * For greedy labels, forward-slash is not encoded because it is expected that the
     * label contents will include multiple path components.
     *
     * Swift .urlPercentEncoding() method encodes forward slashes by default.
     */
    private fun urlEncoding(greedy: Boolean): String {
        val options = "encodeForwardSlash: false".takeIf { greedy } ?: ""
        return ".urlPercentEncoding($options)"
    }
}
