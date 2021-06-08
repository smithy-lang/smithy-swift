package software.amazon.smithy.swift.codegen.integration.serde.formurl.trait

import software.amazon.smithy.aws.traits.protocols.Ec2QueryNameTrait
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.integration.serde.xml.trait.XMLNameTraitGenerator
import software.amazon.smithy.swift.codegen.model.getTrait

class Ec2QueryNameTraitGenerator(val xmlNameValue: String) {
    companion object {
        fun construct(shape: Shape, defaultMemberName: String): Ec2QueryNameTraitGenerator {
            shape.getTrait<Ec2QueryNameTrait>()?.let {
                return Ec2QueryNameTraitGenerator(it.value)
            }
            val generator = XMLNameTraitGenerator.construct(shape, defaultMemberName)
            return Ec2QueryNameTraitGenerator(generator.xmlNameValue.capitalize())
        }
    }
    override fun toString(): String {
        return xmlNameValue
    }
}
