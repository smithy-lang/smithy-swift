package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.ServiceGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HttpResponseTraitPayload
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HttpResponseTraitQueryParams
import software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits.HttpResponseTraitResponseCode

class HttpResponseBindingOutputGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
    val op: OperationShape,
    val httpBindingResolver: HttpBindingResolver,
    val defaultTimestampFormat: TimestampFormatTrait.Format
) {

    fun render() {
        if (op.output.isEmpty) {
            return
        }
        val opIndex = OperationIndex.of(ctx.model)
        val outputShapeName = ServiceGenerator.getOperationOutputShapeName(ctx.symbolProvider, opIndex, op)
        var responseBindings = httpBindingResolver.responseBindings(op)
        val headerBindings = responseBindings
            .filter { it.location == HttpBinding.Location.HEADER }
            .sortedBy { it.memberName }
        val rootNamespace = ctx.settings.moduleName
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$outputShapeName+HttpResponseBinding.swift")
            .name(outputShapeName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            writer.openBlock("extension $outputShapeName: \$T {", "}", ClientRuntimeTypes.Http.HttpResponseBinding) {
                writer.openBlock("public init (httpResponse: \$T, decoder: \$D) throws {", "}", ClientRuntimeTypes.Http.HttpResponse, ClientRuntimeTypes.Serde.ResponseDecoder) {
                    HttpResponseHeaders(ctx, headerBindings, defaultTimestampFormat, writer).render()
                    HttpResponsePrefixHeaders(ctx, responseBindings, writer).render()
                    HttpResponseTraitPayload(ctx, responseBindings, outputShapeName, writer).render()
                    HttpResponseTraitQueryParams(ctx, responseBindings, writer).render()
                    HttpResponseTraitResponseCode(ctx, responseBindings, writer).render()
                }
            }
            writer.write("")
        }
    }
}
