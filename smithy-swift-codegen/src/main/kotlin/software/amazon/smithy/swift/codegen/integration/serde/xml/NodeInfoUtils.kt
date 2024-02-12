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

        return nodeInfo(resolvedName, "", xmlNamespaceParam)
    }

    fun nodeInfo(member: MemberShape, forRootNode: Boolean = false): String {
        val targetShape = ctx.model.expectShape(member.target)

        val resolvedName = if (forRootNode) {
            val xmlName = member.getTrait<XmlNameTrait>()?.value ?: targetShape.getTrait<XmlNameTrait>()?.value
            xmlName ?: ctx.symbolProvider.toSymbol(targetShape).name
        } else {
            member.getTrait<XmlNameTrait>()?.value ?: member.memberName
        }

        val xmlAttributeParam = ", location: .attribute".takeIf { member.hasTrait<XmlAttributeTrait>() } ?: ""

        val xmlNamespaceTrait = member.getTrait<XmlNamespaceTrait>() ?: targetShape.getTrait<XmlNamespaceTrait>() ?: ctx.service.getTrait<XmlNamespaceTrait>().takeIf { forRootNode }
        val xmlNamespaceParam = namespaceParam(xmlNamespaceTrait)

        return nodeInfo(resolvedName, xmlAttributeParam, xmlNamespaceParam)
    }

    private fun namespaceParam(xmlNamespaceTrait: XmlNamespaceTrait?): String {
        return xmlNamespaceTrait?.let {
            writer.format(
                ", namespaceDef: .init(prefix: \$S, uri: \$S)",
                it.prefix,
                it.uri
            )
        } ?: ""
    }

    private fun nodeInfo(resolvedName: String, xmlAttributeParam: String, xmlNamespaceParam: String): String {
        if (xmlAttributeParam == "" && xmlNamespaceParam == "") {
            return writer.format("\$S", resolvedName)
        } else {
            return writer.format(
                ".init(\$S\$L\$L)",
                resolvedName,
                xmlAttributeParam,
                xmlNamespaceParam
            )
        }
    }
}
