package software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits

import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class HttpResponseTraitPayload(
    val ctx: ProtocolGenerator.GenerationContext,
    val responseBindings: List<HttpBindingDescriptor>,
    val outputShapeName: String,
    val writer: SwiftWriter
) {
    fun render() {
        val httpPayload = responseBindings.firstOrNull { it.location == HttpBinding.Location.PAYLOAD }
        if (httpPayload != null) {
            HttpResponseTraitWithHttpPayload(ctx, httpPayload, writer).render()
        } else {
            HttpResponseTraitWithoutHttpPayload(ctx, responseBindings, outputShapeName, writer).render()
        }
    }
}
