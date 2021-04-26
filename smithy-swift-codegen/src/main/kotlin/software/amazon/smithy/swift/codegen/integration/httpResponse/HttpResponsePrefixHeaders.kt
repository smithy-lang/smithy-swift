package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.SetShape
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class HttpResponsePrefixHeaders(
    val ctx: ProtocolGenerator.GenerationContext,
    val binding: HttpBindingDescriptor,
    val writer: SwiftWriter
) {
    fun render() {
        val targetShape = ctx.model.expectShape(binding.member.target) as? MapShape
            ?: throw CodegenException("prefixHeader bindings can only be attached to Map shapes")

        val targetValueShape = ctx.model.expectShape(targetShape.value.target)
        val targetValueSymbol = ctx.symbolProvider.toSymbol(targetValueShape)
        val prefix = binding.locationName
        val memberName = ctx.symbolProvider.toMemberName(binding.member)

        val keyCollName = "keysFor${memberName.capitalize()}"
        val filter = if (prefix.isNotEmpty()) ".filter({ $0.starts(with: \"$prefix\") })" else ""

        writer.write("let $keyCollName = httpResponse.headers.dictionary.keys\$L", filter)
        writer.openBlock("if (!$keyCollName.isEmpty) {")
            .write("var mapMember = [String: ${targetValueSymbol.name}]()")
            .openBlock("for headerKey in $keyCollName {")
            .call {
                val mapMemberValue = when (targetValueShape) {
                    is StringShape -> "httpResponse.headers.dictionary[headerKey]?[0]"
                    is ListShape -> "httpResponse.headers.dictionary[headerKey]"
                    is SetShape -> "Set(httpResponse.headers.dictionary[headerKey])"
                    else -> throw CodegenException("invalid httpPrefixHeaders usage on ${binding.member}")
                }
                // get()/getAll() returns String? or List<String>?, this shouldn't ever trigger the continue though...
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
