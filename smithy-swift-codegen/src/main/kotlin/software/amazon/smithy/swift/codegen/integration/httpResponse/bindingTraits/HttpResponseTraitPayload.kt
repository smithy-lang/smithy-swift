package software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits

import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.HttpResponseBindingRenderable

interface HttpResponseTraitPayloadFactory {
    fun construct(
        ctx: ProtocolGenerator.GenerationContext,
        responseBindings: List<HttpBindingDescriptor>,
        errorShapeName: String,
        writer: SwiftWriter
    ): HttpResponseBindingRenderable
}

class HttpResponseTraitPayload(
    val ctx: ProtocolGenerator.GenerationContext,
    val responseBindings: List<HttpBindingDescriptor>,
    val outputShapeName: String,
    val writer: SwiftWriter,
    val httpResponseTraitWithoutPayloadFactory: HttpResponseTraitWithoutHttpPayloadFactory? = null
) : HttpResponseBindingRenderable {
    override fun render() {
        val httpPayload = responseBindings.firstOrNull { it.location == HttpBinding.Location.PAYLOAD }
        if (httpPayload != null) {
            HttpResponseTraitWithHttpPayload(ctx, httpPayload, writer).render()
        } else {
            val httpResponseTraitWithoutPayload = httpResponseTraitWithoutPayloadFactory?.let {
                it.construct(ctx, responseBindings, outputShapeName, writer)
            } ?: run {
                HttpResponseTraitWithoutHttpPayload(ctx, responseBindings, outputShapeName, writer)
            }
            httpResponseTraitWithoutPayload.render()
        }
    }
}
