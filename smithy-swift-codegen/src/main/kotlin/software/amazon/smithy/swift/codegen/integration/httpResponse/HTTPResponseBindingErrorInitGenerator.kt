package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.declareSection
import software.amazon.smithy.swift.codegen.integration.HTTPProtocolCustomizable
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SectionId
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HTTPResponseTraitPayload
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HTTPResponseTraitResponseCode
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.addImports
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.responseWireProtocol

class HTTPResponseBindingErrorInitGenerator(
    val customizations: HTTPProtocolCustomizable,
) {

    object XMLHttpResponseBindingErrorInit : SectionId
    object XMLHttpResponseBindingErrorInitMemberAssignment : SectionId

    fun render(
        ctx: ProtocolGenerator.GenerationContext,
        structureShape: StructureShape,
        httpBindingResolver: HttpBindingResolver,
    ) {
        val responseBindings = httpBindingResolver.responseBindings(structureShape)
        val headerBindings = responseBindings
            .filter { it.location == HttpBinding.Location.HEADER }
            .sortedBy { it.memberName }
        val needsReader = responseBindings.filter { it.location == HttpBinding.Location.DOCUMENT }.isNotEmpty()
        val needsResponse = responseBindings.filter { it.location == HttpBinding.Location.HEADER || it.location == HttpBinding.Location.PREFIX_HEADERS }.isNotEmpty()
        val rootNamespace = ctx.settings.moduleName
        val errorShape = ctx.symbolProvider.toSymbol(structureShape)

        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/${errorShape.name}+Init.swift")
            .name(errorShape.name)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            writer.addImport(customizations.baseErrorSymbol)
            writer.addImports(ctx.service.responseWireProtocol)
            writer.openBlock("extension \$N {", "}", errorShape) {
                writer.write("")
                writer.openBlock(
                    "static func makeError(baseError: \$N) throws -> \$N {",
                    "}",
                    customizations.baseErrorSymbol,
                    errorShape,
                ) {
                    if (needsReader) {
                        writer.write("let reader = baseError.errorBodyReader")
                    }
                    if (needsResponse) {
                        writer.write("let httpResponse = baseError.httpResponse")
                    }
                    writer.write("var value = \$N()", errorShape)
                    HTTPResponseHeaders(ctx, true, headerBindings, customizations.defaultTimestampFormat, writer).render()
                    HTTPResponsePrefixHeaders(ctx, responseBindings, writer).render()
                    httpResponseTraitPayload(ctx, responseBindings, structureShape, writer)
                    HTTPResponseTraitResponseCode(ctx, responseBindings, writer).render()
                    writer.write("value.httpResponse = baseError.httpResponse")
                    writer.write("value.requestID = baseError.requestID")
                    writer.write("value.message = baseError.message")
                    writer.declareSection(XMLHttpResponseBindingErrorInitMemberAssignment)
                    writer.write("return value")
                }
            }
            writer.write("")
        }
    }

    private fun httpResponseTraitPayload(ctx: ProtocolGenerator.GenerationContext, responseBindings: List<HttpBindingDescriptor>, errorShape: Shape, writer: SwiftWriter) {
        HTTPResponseTraitPayload(ctx, responseBindings, errorShape, writer, customizations).render()
    }
}
