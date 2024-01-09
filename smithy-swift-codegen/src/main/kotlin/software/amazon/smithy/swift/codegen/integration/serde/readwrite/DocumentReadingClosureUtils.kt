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

class DocumentReadingClosureUtils(
    val ctx: ProtocolGenerator.GenerationContext,
    val writer: SwiftWriter
) {
    fun closure(memberShape: MemberShape): String {
        val rootNodeInfo = NodeInfoUtils(ctx, writer).nodeInfo(memberShape, true)
        return closure(rootNodeInfo)
    }

    fun closure(valueShape: Shape): String {
        val rootNodeInfo = NodeInfoUtils(ctx, writer).nodeInfo(valueShape)
        return closure(rootNodeInfo)
    }
    private fun closure(rootNodeInfo: String): String {
        when (ctx.service.responseWireProtocol) {
            WireProtocol.XML -> {
                return writer.format("\$N.documentReadingClosure(rootNodeInfo: \$L)", readWriteSymbol(), rootNodeInfo)
            }
            WireProtocol.FORM_URL, WireProtocol.JSON -> {
                return writer.format("\$N.documentReadingClosure(decoder: decoder)", readWriteSymbol())
            }
        }
    }

    fun readerSymbol(): Symbol {
        when (ctx.service.responseWireProtocol) {
            WireProtocol.XML -> {
                writer.addImport(SwiftDependency.SMITHY_XML.target)
                return SmithyXMLTypes.Reader
            }
            WireProtocol.FORM_URL -> {
                // not used
                throw Exception("FormURL decoding not implemented")
            }
            WireProtocol.JSON -> {
                return ClientRuntimeTypes.Serde.JSONReader
            }
        }
    }

    private fun readWriteSymbol(): Symbol {
        when (ctx.service.responseWireProtocol) {
            WireProtocol.XML -> {
                writer.addImport(SwiftDependency.SMITHY_XML.target)
                return SmithyXMLTypes.XMLReadWrite
            }
            WireProtocol.FORM_URL -> {
                writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                return ClientRuntimeTypes.Serde.FormURLReadWrite
            }
            WireProtocol.JSON -> {
                writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                return ClientRuntimeTypes.Serde.JSONReadWrite
            }
        }
    }
}
