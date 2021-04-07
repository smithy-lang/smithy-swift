package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.XmlAttributeTrait
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.isInHttpBody
import software.amazon.smithy.swift.codegen.integration.serde.xml.trait.NameTraitGenerator

class DynamicNodeEncodingXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val shape: Shape,
    private val xmlNamespaces: Set<String>
) {
    fun render() {
        val symbol = ctx.symbolProvider.toSymbol(shape)
        val symbolName = symbol.name
        val rootNamespace = ctx.settings.moduleName
        val encodeSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$symbolName+DynamicNodeEncoding.swift")
            .name(symbolName)
            .build()
        ctx.delegator.useShapeWriter(encodeSymbol) { writer ->
            writer.openBlock("extension $symbolName: DynamicNodeEncoding {", "}") {
                writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                renderNodeEncodingConformance(writer)
            }
        }
    }

    private fun renderNodeEncodingConformance(writer: SwiftWriter) {
        writer.openBlock("public static func nodeEncoding(for key: CodingKey) -> NodeEncoding {", "}") {
            renderNamespaces(xmlNamespaces, writer)
            renderAttributes(writer)
            writer.write("return .element")
        }
    }

    private fun renderNamespaces(namespaces: Set<String>, writer: SwiftWriter) {
        renderGenericAttributeElementBlock(writer, "xmlNamespaceValues", namespaces)
    }

    private fun renderAttributes(writer: SwiftWriter) {
        val httpBodyMembers = shape.members()
            .filter { it.isInHttpBody() }
            .filter { it.hasTrait(XmlAttributeTrait::class.java) }
            .map { NameTraitGenerator.construct(it, ctx.symbolProvider.toMemberName(it)).toString() }
            .toSet()
        renderGenericAttributeElementBlock(writer, "codingKeys", httpBodyMembers)
    }

    private fun renderGenericAttributeElementBlock(writer: SwiftWriter, variableName: String, attributes: Set<String>) {
        if (attributes.isEmpty()) {
            return
        }
        writer.openBlock("let $variableName = [", "]") {
            val itemIndividuallyQuoted = attributes.map { "\"${it}\"" }.sorted()
            writer.write(itemIndividuallyQuoted.joinToString(", \n"))
        }
        writer.openBlock("if let key = key as? Key {", "}") {
            writer.openBlock("if $variableName.contains(key.stringValue) {", "}") {
                writer.write("return .attribute")
            }
        }
    }
}
