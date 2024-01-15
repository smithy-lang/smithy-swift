package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.aws.traits.customizations.S3UnwrappedXmlOutputTrait
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SmithyXMLTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.XMLHttpResponseTraitPayload
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.XMLHttpResponseTraitQueryParams
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.XMLHttpResponseTraitResponseCode
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.AWSProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.awsProtocol
import software.amazon.smithy.swift.codegen.model.hasTrait

class XMLHttpResponseBindingOutputGenerator() : HttpResponseBindingOutputGeneratable {

    override fun render(
        ctx: ProtocolGenerator.GenerationContext,
        op: OperationShape,
        httpBindingResolver: HttpBindingResolver,
        defaultTimestampFormat: TimestampFormatTrait.Format
    ) {
        if (op.output.isEmpty) {
            return
        }
        val outputShape = ctx.model.expectShape(op.outputShape)
        val outputSymbol = MiddlewareShapeUtils.outputSymbol(ctx.symbolProvider, ctx.model, op)
        var responseBindings = httpBindingResolver.responseBindings(op)
        val headerBindings = responseBindings
            .filter { it.location == HttpBinding.Location.HEADER }
            .sortedBy { it.memberName }
        val rootNamespace = ctx.settings.moduleName
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/${outputSymbol.name}+HttpResponseBinding.swift")
            .name(outputSymbol.name)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            writer.addImport(SwiftDependency.SMITHY_XML.target)
            writer.addImport(SwiftDependency.SMITHY_READ_WRITE.target)
            writer.openBlock("extension \$N {", "}", outputSymbol) {
                writer.write("")
                writer.openBlock(
                    "static var httpBinding: \$N<\$N, \$N> {",
                    "}",
                    ClientRuntimeTypes.Http.HTTPResponseOutputBinding,
                    outputSymbol,
                    SmithyXMLTypes.Reader,
                ) {
                    writer.openBlock("{ httpResponse, responseReader in", "}") {
                        writer.write("let reader = \$L", reader(ctx, op, writer))
                        writer.write("var value = \$N()", outputSymbol)
                        XMLHttpResponseHeaders(ctx, false, headerBindings, defaultTimestampFormat, writer).render()
                        XMLHttpResponsePrefixHeaders(ctx, responseBindings, writer).render()
                        XMLHttpResponseTraitPayload(ctx, responseBindings, outputShape, writer).render()
                        XMLHttpResponseTraitQueryParams(ctx, responseBindings, writer).render()
                        XMLHttpResponseTraitResponseCode(ctx, responseBindings, writer).render()
                        writer.write("return value")
                    }
                }
            }
            writer.write("")
        }
    }

    private fun reader(ctx: ProtocolGenerator.GenerationContext, op: OperationShape, writer: SwiftWriter): String {
        return when (ctx.service.awsProtocol) {
            // AwsQuery responses are nested in an XML element named with the operation's name + "Result"
            AWSProtocol.AWS_QUERY -> writer.format("responseReader[\$S]", "${op.id.name}Result")
            // For RestXML, "unwrap" the reader when the operation has S3UnwrappedXmlOutputTrait.
            AWSProtocol.REST_XML -> "responseReader.unwrap()".takeIf { op.hasTrait<S3UnwrappedXmlOutputTrait>() } ?: "responseReader"
            // Other AWS protocols simply read the root element
            else -> "responseReader"
        }
    }
}
