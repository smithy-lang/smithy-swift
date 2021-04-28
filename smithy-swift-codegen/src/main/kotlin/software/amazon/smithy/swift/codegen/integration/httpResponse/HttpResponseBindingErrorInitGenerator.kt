package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HttpResponseTraitPayload
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HttpResponseTraitQueryParams
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HttpResponseTraitResponseCode

class HttpResponseBindingErrorInitGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
    val shape: StructureShape,
    val httpBindingResolver: HttpBindingResolver,
    val serviceErrorProtocolSymbol: Symbol,
    val defaultTimestampFormat: TimestampFormatTrait.Format
) {

    fun render() {
        val responseBindings = httpBindingResolver.responseBindings(shape)
        val headerBindings = responseBindings
            .filter { it.location == HttpBinding.Location.HEADER }
            .sortedBy { it.memberName }
        val rootNamespace = ctx.settings.moduleName
        val errorShapeName = ctx.symbolProvider.toSymbol(shape).name

        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$errorShapeName+Init.swift")
            .name(errorShapeName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            writer.addImport(serviceErrorProtocolSymbol)
            writer.openBlock("extension \$L: \$L {", "}", errorShapeName, serviceErrorProtocolSymbol.name) {
                writer.openBlock("public init (httpResponse: HttpResponse, decoder: ResponseDecoder? = nil, message: String? = nil, requestID: String? = nil) throws {", "}") {
                    HttpResponseHeaders(ctx, headerBindings, defaultTimestampFormat, writer).render()
                    HttpResponsePrefixHeaders(ctx, responseBindings, writer).render()
                    HttpResponseTraitPayload(ctx, responseBindings, errorShapeName, writer).render()
                    HttpResponseTraitQueryParams(ctx, responseBindings, writer).render()
                    HttpResponseTraitResponseCode(ctx, responseBindings, writer).render()
                    writer.write("self._headers = httpResponse.headers")
                    writer.write("self._statusCode = httpResponse.statusCode")
                    writer.write("self._requestID = requestID")
                    writer.write("self._message = message")
                }
            }
            writer.write("")
        }
    }
}
