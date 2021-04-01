package software.amazon.smithy.swift.codegen.integration.serde.xml.trait

import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.XmlNamespaceTrait
import software.amazon.smithy.swift.codegen.SwiftWriter

class NamespaceTraitGenerator(val key: String, val value: String) {
    companion object {
        fun construct(shape: Shape): NamespaceTraitGenerator? {
            if (shape.hasTrait(XmlNamespaceTrait::class.java)) {
                val trait = shape.getTrait(XmlNamespaceTrait::class.java).get()
                val key = if (trait.prefix.isPresent) "xmlns:${trait.prefix.get()}" else "xmlns"
                val namespaceValue = trait.uri
                return NamespaceTraitGenerator(key, namespaceValue)
            }
            return null
        }
    }

    fun render(writer: SwiftWriter, container: String): NamespaceTraitGenerator {
        writer.write("try $container.encode(\"$value\", forKey: Key(\"${key}\"))")
        return this
    }

    fun appendKey(xmlNamespaces: MutableSet<String>): NamespaceTraitGenerator {
        xmlNamespaces.add(key)
        return this
    }
}
