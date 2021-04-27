package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.ServiceGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

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
            writer.addFoundationImport()
            writer.openBlock("extension $outputShapeName: HttpResponseBinding {", "}") {
                writer.openBlock("public init (httpResponse: HttpResponse, decoder: ResponseDecoder? = nil) throws {", "}") {
                    HttpResponseHeaders(ctx, headerBindings, defaultTimestampFormat, writer).render()
                    responseBindings.firstOrNull { it.location == HttpBinding.Location.PREFIX_HEADERS }
                        ?.let {
                            HttpResponsePrefixHeaders(ctx, it, writer).render()
                        }
                    writer.write("")
                    HttpResponsePayload(ctx, responseBindings, outputShapeName, writer).render()
                }
            }
            writer.write("")
        }
    }
}
