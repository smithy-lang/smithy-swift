/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.xml.trait

import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.XmlNameTrait
import software.amazon.smithy.swift.codegen.model.getTrait

class XMLNameTraitGenerator(val xmlNameValue: String) {
    companion object {
        fun construct(shape: Shape, defaultMemberName: String): XMLNameTraitGenerator {
            shape.getTrait<XmlNameTrait>()?.let {
                return XMLNameTraitGenerator(it.value.toString())
            }
            val unquotedDefaultMemberName = defaultMemberName.removeSurrounding("`", "`")
            return XMLNameTraitGenerator(unquotedDefaultMemberName)
        }
    }
    override fun toString(): String {
        return xmlNameValue
    }
}
