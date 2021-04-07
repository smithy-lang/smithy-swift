package software.amazon.smithy.swift.codegen.integration.serde.xml.collection

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.serde.xml.trait.XMLNameTraitGenerator

class CollectionMember(
    val namespace: String,
    val memberTagName: String
) {
    companion object {
        fun constructCollectionMember(memberShape: MemberShape, level: Int): CollectionMember {
            val memberTagName = XMLNameTraitGenerator.construct(memberShape, "member").toString()
            val namespace = "KeyVal$level"
            return CollectionMember(namespace, memberTagName)
        }
    }
    fun renderStructs(writer: SwiftWriter) {
        writer.write("struct $namespace{struct $memberTagName{}}")
    }
    fun keyTag(): String {
        return "$namespace.$memberTagName"
    }
}
