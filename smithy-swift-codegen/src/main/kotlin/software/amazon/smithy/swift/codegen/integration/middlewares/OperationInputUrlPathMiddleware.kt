package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep
import software.amazon.smithy.swift.codegen.model.isBoxed
import software.amazon.smithy.swift.codegen.model.toMemberNames

class OperationInputUrlPathMiddleware(
    val model: Model,
    val symbolProvider: SymbolProvider,
    val httpBindingResolver: HttpBindingResolver,
    private val hasUrlPrefix: Boolean = false
) : MiddlewareRenderable {

    override val name = "OperationInputUrlPathMiddleware"

    override val middlewareStep = MiddlewareStep.INITIALIZESTEP

    override val position = MiddlewarePosition.AFTER

    override fun render(
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String
    ) {
        val urlPath = getUrlPath(writer, op)
        var parameters = "urlPath: \"$urlPath\""
        if (hasUrlPrefix) {
            parameters += ", urlPrefix: urlPrefix"
        }
        val inputShapeName = MiddlewareShapeUtils.inputSymbol(symbolProvider, model, op).name
        val outputShapeName = MiddlewareShapeUtils.outputSymbol(symbolProvider, model, op).name
        val errorShapeName = MiddlewareShapeUtils.outputErrorSymbolName(op)
        writer.write("$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, middleware: \$N<$inputShapeName, $outputShapeName, $errorShapeName>($parameters))", ClientRuntimeTypes.Middleware.URLPathMiddleware)
    }

    private fun getUrlPath(writer: SwiftWriter, op: OperationShape): String {
        val httpTrait = httpBindingResolver.httpTrait(op)
        val requestBindings = httpBindingResolver.requestBindings(op)
        val pathBindings = requestBindings.filter { it.location == HttpBinding.Location.LABEL }
        val resolvedURIComponents = mutableListOf<String>()
        httpTrait.uri.segments.forEach {
            if (it.isLabel) {
                // spec dictates member name and label name MUST be the same
                val binding = pathBindings.find { binding ->
                    binding.memberName == it.content
                } ?: throw CodegenException("failed to find corresponding member for httpLabel `${it.content}")

                // shape must be string, number, boolean, or timestamp
                val targetShape = model.expectShape(binding.member.target)
                val labelMemberName = symbolProvider.toMemberNames(binding.member).first.decapitalize()
                val formattedLabel: String = when (targetShape.type) {
                    ShapeType.TIMESTAMP -> {
                        val bindingIndex = HttpBindingIndex.of(model)
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
                val isBoxed = symbolProvider.toSymbol(targetShape).isBoxed()

                // unwrap the label members if boxed
                if (isBoxed) {
                    writer.openBlock("guard let $labelMemberName = input.$labelMemberName else {", "}") {
                        writer.write("completion(.failure(.client(\$N.pathCreationFailed((\"$labelMemberName is nil and needs a value for the path of this operation\")))))",
                            ClientRuntimeTypes.Core.ClientError
                        )
                        writer.write("return")
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
        return uri
    }
}
