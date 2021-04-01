package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.traits.XmlNameTrait

class XMLNameValue {
    companion object {
        fun getCustomNameIfAvailable(memberShape: MemberShape, defaultValue: String): String {
            if (memberShape.hasTrait(XmlNameTrait::class.java)) {
                return memberShape.getTrait(XmlNameTrait::class.java)?.get()?.value ?: defaultValue
            }
            return defaultValue
        }
    }
}
