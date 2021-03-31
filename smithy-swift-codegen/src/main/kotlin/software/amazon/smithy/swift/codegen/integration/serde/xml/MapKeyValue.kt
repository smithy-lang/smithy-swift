package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.swift.codegen.SwiftWriter

class MapKeyValue(
    val namespace: String,
    val keyTagName: String,
    val valueTagName: String
) {
    companion object {
        fun constructMapKeyValue(keyMemberShape: MemberShape, valueMemberShape: MemberShape, level: Int): MapKeyValue {
            val keyTagName = XMLNameValue.getCustomNameIfAvailable(keyMemberShape, "key")
            val valueTagName = XMLNameValue.getCustomNameIfAvailable(valueMemberShape, "value")
            val namespace = "KeyVal$level"
            return MapKeyValue(namespace, keyTagName, valueTagName)
        }
    }
    fun renderStructs(writer: SwiftWriter) {
        writer.write("struct $namespace{struct $keyTagName{}; struct $valueTagName{}}")
    }
    fun keyTag(): String {
        return "$namespace.$keyTagName"
    }
    fun valueTag(): String {
        return "$namespace.$valueTagName"
    }
}
