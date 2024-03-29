/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.xml.collection

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.serde.xml.trait.XMLNameTraitGenerator

class MapKeyValue(
    val namespace: String,
    val keyTagName: String,
    val valueTagName: String
) {
    companion object {
        fun constructMapKeyValue(keyMemberShape: MemberShape, valueMemberShape: MemberShape, level: Int): MapKeyValue {
            val keyTagName = XMLNameTraitGenerator.construct(keyMemberShape, "key").toString()
            val valueTagName = XMLNameTraitGenerator.construct(valueMemberShape, "value").toString()
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
