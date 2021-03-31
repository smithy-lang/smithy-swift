package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.swift.codegen.SwiftWriter

class CollectionMember(
    val namespace: String,
    val memberTagName: String
) {
    companion object {
        fun constructCollectionMember(memberShape: MemberShape, level: Int): CollectionMember {
            val memberTagName = XMLNameValue.getCustomNameIfAvailable(memberShape, "member")
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
