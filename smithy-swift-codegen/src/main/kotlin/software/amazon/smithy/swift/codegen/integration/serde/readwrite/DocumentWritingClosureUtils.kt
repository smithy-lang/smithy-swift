package software.amazon.smithy.swift.codegen.integration.serde.readwrite

import software.amazon.smithy.aws.traits.protocols.AwsQueryTrait
import software.amazon.smithy.aws.traits.protocols.Ec2QueryTrait
import software.amazon.smithy.aws.traits.protocols.RestXmlTrait
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SmithyXMLTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.xml.NodeInfoUtils
import software.amazon.smithy.swift.codegen.model.hasTrait

class DocumentWritingClosureUtils(
    val ctx: ProtocolGenerator.GenerationContext,
    val writer: SwiftWriter
) {
    private enum class AwsProtocol {
        XML, FORM_URL, JSON
    }

    private val awsProtocol: AwsProtocol
        get() = if (ctx.service.hasTrait<RestXmlTrait>()) {
            AwsProtocol.XML
        } else if (ctx.service.hasTrait<AwsQueryTrait>() || ctx.service.hasTrait<Ec2QueryTrait>()) {
            AwsProtocol.FORM_URL
        } else {
            AwsProtocol.JSON
        }

    fun closure(memberShape: MemberShape): String {
        val rootNodeInfo = NodeInfoUtils(ctx, writer).nodeInfo(memberShape, true)
        return closure(rootNodeInfo)
    }

    fun closure(valueShape: Shape): String {
        val rootNodeInfo = NodeInfoUtils(ctx, writer).nodeInfo(valueShape)
        return closure(rootNodeInfo)
    }
    private fun closure(rootNodeInfo: String): String {
        when (awsProtocol) {
            AwsProtocol.XML -> {
                return writer.format("\$N.documentWritingClosure(rootNodeInfo: \$L)", readWriteSymbol(), rootNodeInfo)
            }
            AwsProtocol.FORM_URL, AwsProtocol.JSON -> {
                return writer.format("\$N.documentWritingClosure(encoder: encoder)", readWriteSymbol())
            }
        }
    }

    fun writerSymbol(): Symbol {
        when (awsProtocol) {
            AwsProtocol.XML -> {
                writer.addImport(SwiftDependency.SMITHY_XML.target)
                return SmithyXMLTypes.Writer
            }
            AwsProtocol.FORM_URL -> {
                return ClientRuntimeTypes.Serde.FormURLWriter
            }
            AwsProtocol.JSON -> {
                return ClientRuntimeTypes.Serde.JSONWriter
            }
        }
    }

    private fun readWriteSymbol(): Symbol {
        when (awsProtocol) {
            AwsProtocol.XML -> {
                writer.addImport(SwiftDependency.SMITHY_XML.target)
                return SmithyXMLTypes.XMLReadWrite
            }
            AwsProtocol.FORM_URL -> {
                writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                return ClientRuntimeTypes.Serde.FormURLReadWrite
            }
            AwsProtocol.JSON -> {
                writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                return ClientRuntimeTypes.Serde.JSONReadWrite
            }
        }
    }
}
