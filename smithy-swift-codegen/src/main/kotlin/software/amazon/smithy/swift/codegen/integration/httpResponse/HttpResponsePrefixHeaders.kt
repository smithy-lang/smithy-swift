/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.SetShape
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class HttpResponsePrefixHeaders(
    val ctx: ProtocolGenerator.GenerationContext,
    val responseBindings: List<HttpBindingDescriptor>,
    val writer: SwiftWriter
) {
    fun render() {
        val binding = responseBindings.firstOrNull { it.location == HttpBinding.Location.PREFIX_HEADERS }
        if (binding != null) {
            renderBinding(binding)
        }
    }

    private fun renderBinding(binding: HttpBindingDescriptor) {
        val targetShape = ctx.model.expectShape(binding.member.target) as? MapShape
            ?: throw CodegenException("prefixHeader bindings can only be attached to Map shapes")

        val targetValueShape = ctx.model.expectShape(targetShape.value.target)
        val targetValueSymbol = ctx.symbolProvider.toSymbol(targetValueShape)
        val prefix = binding.locationName
        val memberName = ctx.symbolProvider.toMemberName(binding.member)

        val keyCollName = "keysFor${memberName.capitalize()}"
        val filter = if (prefix.isNotEmpty()) ".filter({ $0.starts(with: \"$prefix\") })" else ""

        writer.write("let $keyCollName = await httpResponse.headers.dictionary.keys\$L", filter)
        writer.openBlock("if (!$keyCollName.isEmpty) {")
            .write("var mapMember = [\$N: ${targetValueSymbol.name}]()", SwiftTypes.String)
            .openBlock("for headerKey in $keyCollName {")
            .call {
                val mapMemberValue = when (targetValueShape) {
                    is StringShape -> "await httpResponse.headers.dictionary[headerKey]?[0]"
                    is ListShape -> "await httpResponse.headers.dictionary[headerKey]"
                    is SetShape -> "Set(await httpResponse.headers.dictionary[headerKey])"
                    else -> throw CodegenException("invalid httpPrefixHeaders usage on ${binding.member}")
                }
                writer.write("let mapMemberValue = $mapMemberValue")
                if (prefix.isNotEmpty()) {
                    writer.write("let mapMemberKey = headerKey.removePrefix(\$S)", prefix)
                    writer.write("mapMember[mapMemberKey] = mapMemberValue")
                } else {
                    writer.write("mapMember[headerKey] = mapMemberValue")
                }
            }
            .closeBlock("}")
            .write("self.\$L = mapMember", memberName)
            .closeBlock("} else {")
        writer.indent()
        writer.write("self.\$L = [:]", memberName)
        writer.dedent()
        writer.write("}")
    }
}
