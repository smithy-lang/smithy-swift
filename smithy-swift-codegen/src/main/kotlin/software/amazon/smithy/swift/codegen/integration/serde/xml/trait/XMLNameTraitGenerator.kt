package software.amazon.smithy.swift.codegen.integration.serde.xml.trait

import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.XmlNameTrait

class XMLNameTraitGenerator(val xmlNameValue: String) {
    companion object {
        fun construct(shape: Shape, defaultMemberName: String): XMLNameTraitGenerator {
            if (shape.hasTrait(XmlNameTrait::class.java)) {
                val trait = shape.getTrait(XmlNameTrait::class.java).get()
                return XMLNameTraitGenerator(trait.value)
            }
            val unquotedDefaultMemberName = defaultMemberName.removeSurrounding("`", "`")
            return XMLNameTraitGenerator(unquotedDefaultMemberName)
        }
    }
    override fun toString(): String {
        return xmlNameValue
    }
}
