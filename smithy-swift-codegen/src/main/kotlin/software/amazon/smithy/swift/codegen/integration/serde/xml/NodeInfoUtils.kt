package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.XmlAttributeTrait
import software.amazon.smithy.model.traits.XmlNameTrait
import software.amazon.smithy.model.traits.XmlNamespaceTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait

class NodeInfoUtils(
    val ctx: ProtocolGenerator.GenerationContext,
    val writer: SwiftWriter
) {

    fun nodeInfo(shape: Shape): String {
        val xmlName = shape.getTrait<XmlNameTrait>()?.value
        val symbol = ctx.symbolProvider.toSymbol(shape)
        val resolvedName = xmlName ?: symbol.name

        val xmlNamespaceTrait = shape.getTrait<XmlNamespaceTrait>() ?: ctx.service.getTrait<XmlNamespaceTrait>()
        val xmlNamespaceParam = namespaceParam(xmlNamespaceTrait)

        return writer.format(
            ".init(\$S\$L)",
            resolvedName,
            xmlNamespaceParam
        )
    }

    fun nodeInfo(member: MemberShape, forRootNode: Boolean = false): String {
        val targetShape = ctx.model.expectShape(member.target)

        val resolvedName: String
        if (forRootNode) {
            val xmlName = member.getTrait<XmlNameTrait>()?.value ?: targetShape.getTrait<XmlNameTrait>()?.value
            if (xmlName != null) {
                resolvedName = xmlName
            } else {
                resolvedName = ctx.symbolProvider.toSymbol(targetShape).name
            }
        } else {
            resolvedName = member.getTrait<XmlNameTrait>()?.value ?: member.memberName
        }

        val xmlAttributeParam = ", location: .attribute".takeIf { member.hasTrait<XmlAttributeTrait>() } ?: ""

        val xmlNamespaceTrait = member.getTrait<XmlNamespaceTrait>() ?: targetShape.getTrait<XmlNamespaceTrait>() ?: ctx.service.getTrait<XmlNamespaceTrait>().takeIf { forRootNode }
        val xmlNamespaceParam = namespaceParam(xmlNamespaceTrait)

        return writer.format(
            ".init(\$S\$L\$L)",
            resolvedName,
            xmlAttributeParam,
            xmlNamespaceParam
        )
    }

    private fun namespaceParam(xmlNamespaceTrait: XmlNamespaceTrait?): String {
        if (xmlNamespaceTrait != null) {
            return writer.format(
                ", namespace: .init(prefix: \$S, uri: \$S)",
                xmlNamespaceTrait.prefix,
                xmlNamespaceTrait.uri
            )
        } else {
            return ""
        }
    }
}
