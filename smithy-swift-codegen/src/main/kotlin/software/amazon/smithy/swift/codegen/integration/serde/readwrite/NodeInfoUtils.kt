package software.amazon.smithy.swift.codegen.integration.serde.readwrite

import software.amazon.smithy.aws.traits.protocols.Ec2QueryNameTrait
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.JsonNameTrait
import software.amazon.smithy.model.traits.XmlAttributeTrait
import software.amazon.smithy.model.traits.XmlNameTrait
import software.amazon.smithy.model.traits.XmlNamespaceTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.model.hasTrait

class NodeInfoUtils(
    val ctx: ProtocolGenerator.GenerationContext,
    val writer: SwiftWriter,
    val wireProtocol: WireProtocol,
) {

    val awsProtocol = ctx.service.awsProtocol
    fun nodeInfo(shape: Shape, forRootNode: Boolean = false): String {
        if (wireProtocol != WireProtocol.XML && forRootNode) return "\"\""
        val xmlName = shape.getTrait<XmlNameTrait>()?.value
        val symbol = ctx.symbolProvider.toSymbol(shape)
        val resolvedName = xmlName ?: symbol.name

        val xmlNamespaceTrait = shape.getTrait<XmlNamespaceTrait>() ?: ctx.service.getTrait<XmlNamespaceTrait>()
        val xmlNamespaceParam = namespaceParam(xmlNamespaceTrait)

        return nodeInfo(resolvedName, "", xmlNamespaceParam)
    }

    fun nodeInfo(member: MemberShape, forRootNode: Boolean = false): String {
        if (wireProtocol != WireProtocol.XML && forRootNode) return "\"\""
        val targetShape = ctx.model.expectShape(member.target)

        val resolvedName = resolvedName(member, forRootNode)

        val xmlAttributeParam = ", location: .attribute".takeIf { member.hasTrait<XmlAttributeTrait>() } ?: ""

        val xmlNamespaceTrait = member.getTrait<XmlNamespaceTrait>() ?: targetShape.getTrait<XmlNamespaceTrait>() ?: ctx.service.getTrait<XmlNamespaceTrait>().takeIf { forRootNode }
        val xmlNamespaceParam = namespaceParam(xmlNamespaceTrait)

        return nodeInfo(resolvedName, xmlAttributeParam, xmlNamespaceParam)
    }

    private fun resolvedName(member: MemberShape, forRootNode: Boolean): String {
        val targetShape = ctx.model.expectShape(member.target)
        when (wireProtocol) {
            WireProtocol.XML -> {
                if (forRootNode) {
                    val xmlName = member.getTrait<XmlNameTrait>()?.value ?: targetShape.getTrait<XmlNameTrait>()?.value
                    return xmlName ?: ctx.symbolProvider.toSymbol(targetShape).name
                } else {
                    return member.getTrait<XmlNameTrait>()?.value ?: member.memberName
                }
            }
            WireProtocol.FORM_URL -> {
                if (forRootNode) {
                    return "\"\""
                } else {
                    if (ctx.service.awsProtocol == AWSProtocol.EC2_QUERY) {
                        return member.getTrait<Ec2QueryNameTrait>()?.value ?: member.getTrait<XmlNameTrait>()?.value?.capitalize() ?: member.memberName.capitalize()
                    } else {
                        return member.getTrait<XmlNameTrait>()?.value ?: member.memberName
                    }
                }
            }
            WireProtocol.JSON -> {
                if (forRootNode) {
                    return "\"\""
                } else if (awsProtocol == AWSProtocol.REST_JSON_1) {
                    return member.getTrait<JsonNameTrait>()?.value ?: member.memberName
                } else {
                    return member.memberName
                }
            }
        }
    }

    private fun namespaceParam(xmlNamespaceTrait: XmlNamespaceTrait?): String {
        if (wireProtocol != WireProtocol.XML) { return "" }
        return xmlNamespaceTrait?.let {
            writer.format(
                ", namespaceDef: .init(prefix: \$S, uri: \$S)",
                it.prefix,
                it.uri
            )
        } ?: ""
    }

    private fun nodeInfo(resolvedName: String, xmlAttributeParam: String, xmlNamespaceParam: String): String {
        if (xmlAttributeParam == "" && xmlNamespaceParam == "" || wireProtocol != WireProtocol.XML) {
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
