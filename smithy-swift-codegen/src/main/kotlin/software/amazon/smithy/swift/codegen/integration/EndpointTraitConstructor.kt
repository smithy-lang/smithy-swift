/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.EndpointTrait
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase

class EndpointTraitConstructor(private val endpointTrait: EndpointTrait, private val inputShape: Shape) {
    fun construct(): String {
        return endpointTrait.hostPrefix.segments.joinToString(separator = "") { segment ->
            if (segment.isLabel) {
                // hostLabel can only target string shapes
                // see: https://smithy.io/2.0/spec/endpoint-traits.html#hostlabel-trait
                val member = inputShape.members().first { it.memberName == segment.content }
                "\\(input.${member.memberName.toLowerCamelCase()}!)"
            } else {
                segment.content
            }
        }
    }
}
