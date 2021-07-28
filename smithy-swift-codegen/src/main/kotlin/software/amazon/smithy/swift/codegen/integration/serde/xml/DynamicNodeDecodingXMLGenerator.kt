package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.XmlAttributeTrait
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.isInHttpBody
import software.amazon.smithy.swift.codegen.model.bodySymbol

class DynamicNodeDecodingXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val shape: Shape,
    private val isForBodyStruct: Boolean
) {
    fun render() {
        val symbol = if (isForBodyStruct) ctx.symbolProvider.toSymbol(shape).bodySymbol() else ctx.symbolProvider.toSymbol(shape)
        val rootNamespace = ctx.settings.moduleName
        val encodeSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/${symbol.name}+DynamicNodeDecoding.swift")
            .name(symbol.name)
            .build()
        ctx.delegator.useShapeWriter(encodeSymbol) { writer ->
            writer.openBlock("extension ${symbol.name}: DynamicNodeDecoding {", "}") {
                writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                renderDynamicNodeDecodingConformance(symbol.name, writer)
            }
        }
    }

    private fun renderDynamicNodeDecodingConformance(symbolName: String, writer: SwiftWriter) {
        val httpBodyMembers = shape.members()
            .filter { it.isInHttpBody() }
            .toList()
        writer.openBlock("public static func nodeDecoding(for key: CodingKey) -> NodeDecoding {", "}") {
            writer.openBlock("switch(key) {", "}") {
                for (bodyMember in httpBodyMembers) {
                    renderBodyMember(symbolName, bodyMember, writer)
                }
                writer.write("default:")
                writer.indent().write("return .element")
                writer.dedent()
            }
        }
    }

    private fun renderBodyMember(symbolName: String, member: MemberShape, writer: SwiftWriter) {
        val memberName = ctx.symbolProvider.toMemberName(member).removeSurrounding("`", "`")
        val elementOrAttribute = if (member.hasTrait(XmlAttributeTrait::class.java)) ".attribute" else ".element"
        writer.write("case $symbolName.CodingKeys.$memberName: return $elementOrAttribute")
    }
}
