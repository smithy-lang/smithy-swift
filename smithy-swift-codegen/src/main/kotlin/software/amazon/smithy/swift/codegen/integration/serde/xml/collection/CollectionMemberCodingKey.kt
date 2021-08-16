/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.xml.collection

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.serde.xml.trait.XMLNameTraitGenerator

class CollectionMemberCodingKey(
    val namespace: String,
    val memberTagName: String
) {
    companion object {
        fun construct(memberShape: MemberShape, level: Int = 0): CollectionMemberCodingKey {
            val memberTagName = XMLNameTraitGenerator.construct(memberShape, "member").toString()
            val namespace = "KeyVal$level"
            return CollectionMemberCodingKey(namespace, memberTagName)
        }
    }
    fun renderStructs(writer: SwiftWriter) {
        writer.write("struct $namespace{struct $memberTagName{}}")
    }
    fun keyTag(): String {
        return "$namespace.$memberTagName"
    }
}
