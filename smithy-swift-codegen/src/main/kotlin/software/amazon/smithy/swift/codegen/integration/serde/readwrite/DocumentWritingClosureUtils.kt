package software.amazon.smithy.swift.codegen.integration.serde.readwrite

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SmithyXMLTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.xml.NodeInfoUtils

class DocumentWritingClosureUtils(
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
        when (ctx.service.requestWireProtocol) {
            WireProtocol.XML -> {
                return writer.format("\$N.documentWritingClosure(rootNodeInfo: \$L)", readWriteSymbol(), rootNodeInfo)
            }
            WireProtocol.FORM_URL, WireProtocol.JSON -> {
                return writer.format("\$N.documentWritingClosure(encoder: encoder)", readWriteSymbol())
            }
        }
    }

    fun writerSymbol(): Symbol {
        when (ctx.service.requestWireProtocol) {
            WireProtocol.XML -> {
                writer.addImport(SwiftDependency.SMITHY_XML.target)
                return SmithyXMLTypes.Writer
            }
            WireProtocol.FORM_URL -> {
                return ClientRuntimeTypes.Serde.FormURLWriter
            }
            WireProtocol.JSON -> {
                return ClientRuntimeTypes.Serde.JSONWriter
            }
        }
    }

    private fun readWriteSymbol(): Symbol {
        when (ctx.service.requestWireProtocol) {
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
