package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SmithyXMLTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.declareSection
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SectionId
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HttpResponseTraitPayload
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HttpResponseTraitPayloadFactory
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HttpResponseTraitQueryParams
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HttpResponseTraitResponseCode
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.XMLHttpResponseTraitQueryParams
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.XMLHttpResponseTraitResponseCode

class XMLHttpResponseBindingErrorInitGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
    val shape: StructureShape,
    val httpBindingResolver: HttpBindingResolver,
    val defaultTimestampFormat: TimestampFormatTrait.Format,
    val httpResponseTraitPayloadFactory: HttpResponseTraitPayloadFactory? = null
) : HttpResponseBindingRenderable {

    object XMLHttpResponseBindingErrorInit : SectionId
    object XMLHttpResponseBindingErrorInitMemberAssignment : SectionId

    override fun render() {
        val responseBindings = httpBindingResolver.responseBindings(shape)
        val headerBindings = responseBindings
            .filter { it.location == HttpBinding.Location.HEADER }
            .sortedBy { it.memberName }
        val rootNamespace = ctx.settings.moduleName
        val errorShape = ctx.symbolProvider.toSymbol(shape)

        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/${errorShape.name}+Init.swift")
            .name(errorShape.name)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            writer.addImport(SwiftDependency.SMITHY_XML.target)
            writer.openBlock("extension \$N {", "}", errorShape) {
                writer.write("")
                writer.declareSection(XMLHttpResponseBindingErrorInit) {
                    writer.write(
                        "static func responseErrorBinding(httpResponse: \$N, reader: \$N, message: \$D, requestID: \$D) async throws -> \$N {",
                        ClientRuntimeTypes.Http.HttpResponse,
                        SmithyXMLTypes.Reader,
                        SwiftTypes.String,
                        SwiftTypes.String,
                        SwiftTypes.Error,
                    )
                }
                writer.indent()
                writer.write("var value = \$N()", errorShape)
                XMLHttpResponseHeaders(ctx, true, headerBindings, defaultTimestampFormat, writer).render()
                XMLHttpResponsePrefixHeaders(ctx, responseBindings, writer).render()
                httpResponseTraitPayload(ctx, responseBindings, shape, writer)
                XMLHttpResponseTraitQueryParams(ctx, responseBindings, writer).render()
                XMLHttpResponseTraitResponseCode(ctx, responseBindings, writer).render()
                writer.write("value.httpResponse = httpResponse")
                writer.write("value.requestID = requestID")
                writer.write("value.message = message")
                writer.declareSection(XMLHttpResponseBindingErrorInitMemberAssignment)
                writer.write("return value")
                writer.dedent()
                writer.write("}")
            }
            writer.write("")
        }
    }

    fun httpResponseTraitPayload(ctx: ProtocolGenerator.GenerationContext, responseBindings: List<HttpBindingDescriptor>, errorShape: Shape, writer: SwiftWriter) {
        val responseTraitPayload = httpResponseTraitPayloadFactory?.let {
            it.construct(ctx, responseBindings, errorShape, writer)
        } ?: run {
            HttpResponseTraitPayload(ctx, responseBindings, errorShape, writer)
        }
        responseTraitPayload.render()
    }
}
