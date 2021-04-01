package software.amazon.smithy.swift.codegen.integration.serde

import software.amazon.smithy.aws.traits.protocols.RestXmlTrait
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.XmlAttributeTrait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.isInHttpBody
import software.amazon.smithy.swift.codegen.integration.serde.xml.DynamicNodeEncodingXMLGenerator

class DynamicNodeEncodingGeneratorStrategy(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val shape: Shape
) {
    fun renderIfNeeded() {
        if (shouldRenderDynamicNodeEncodingProtocol(ctx, shape)) {
            DynamicNodeEncodingXMLGenerator(ctx, shape).render()
        }
    }

    private fun shouldRenderDynamicNodeEncodingProtocol(ctx: ProtocolGenerator.GenerationContext, shape: Shape): Boolean {
        return isRestXmlProtocolAndHasXmlTraitsInMembers(ctx, shape)
    }
}

fun isRestXmlProtocolAndHasXmlTraitsInMembers(ctx: ProtocolGenerator.GenerationContext, shape: Shape): Boolean {
    val isRestXML = ctx.protocol == RestXmlTrait.ID
    if (isRestXML) {
        return shape.members()
            .filter { it.isInHttpBody() }
            .filter { it.hasTrait(XmlAttributeTrait::class.java) }
            .isNotEmpty()
    }
    return false
}