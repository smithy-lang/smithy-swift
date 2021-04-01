package software.amazon.smithy.swift.codegen.integration.serde.xml.trait

import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.XmlNameTrait

class NameTraitGenerator(val xmlNameValue: String) {
    companion object {
        fun construct(shape: Shape, defaultMemberName: String): NameTraitGenerator {
            if (shape.hasTrait(XmlNameTrait::class.java)) {
                val trait = shape.getTrait(XmlNameTrait::class.java).get()
                return NameTraitGenerator(trait.value)
            }
            val unquotedDefaultMemberName = defaultMemberName.removeSurrounding("`", "`")
            return NameTraitGenerator(unquotedDefaultMemberName)
        }
    }
    override fun toString(): String {
        return xmlNameValue
    }
}
