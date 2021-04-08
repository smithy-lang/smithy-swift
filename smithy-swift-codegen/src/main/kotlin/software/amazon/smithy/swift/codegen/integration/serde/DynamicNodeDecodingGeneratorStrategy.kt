package software.amazon.smithy.swift.codegen.integration.serde

import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.xml.DynamicNodeDecodingXMLGenerator

class DynamicNodeDecodingGeneratorStrategy(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val shape: Shape,
    private val isForBodyStruct: Boolean
) {
    fun renderIfNeeded() {
        if (shouldRenderDynamicNodeDecodingProtocol(ctx, shape)) {
            DynamicNodeDecodingXMLGenerator(ctx, shape, isForBodyStruct).render()
        }
    }

    private fun shouldRenderDynamicNodeDecodingProtocol(ctx: ProtocolGenerator.GenerationContext, shape: Shape): Boolean {
        return isRestXmlProtocolAndHasXmlAttributesInMembers(ctx, shape)
    }
}
