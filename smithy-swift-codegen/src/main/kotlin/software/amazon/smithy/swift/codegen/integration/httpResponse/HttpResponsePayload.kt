package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.shapes.BooleanShape
import software.amazon.smithy.model.shapes.ByteShape
import software.amazon.smithy.model.shapes.DoubleShape
import software.amazon.smithy.model.shapes.FloatShape
import software.amazon.smithy.model.shapes.IntegerShape
import software.amazon.smithy.model.shapes.LongShape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.shapes.ShortShape
import software.amazon.smithy.model.traits.HttpQueryTrait
import software.amazon.smithy.model.traits.HttpResponseCodeTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.isBoxed

class HttpResponsePayload(
    val ctx: ProtocolGenerator.GenerationContext,
    val responseBindings: List<HttpBindingDescriptor>,
    val outputShapeName: String,
    val writer: SwiftWriter
) {
    fun render() {
        var queryMemberNames = responseBindings
            .filter { it.location == HttpBinding.Location.QUERY }
            .sortedBy { it.memberName }
            .map { ctx.symbolProvider.toMemberName(it.member) }.toMutableSet()

        val httpPayload = responseBindings.firstOrNull { it.location == HttpBinding.Location.PAYLOAD }
        if (httpPayload != null) {
            renderDeserializeExplicitPayload(ctx, httpPayload, writer)
        } else {
            val bodyMembers = responseBindings
                .filter { it.location == HttpBinding.Location.DOCUMENT }

            queryMemberNames = queryMemberNames.union(
                bodyMembers
                    .filter { it.member.hasTrait(HttpQueryTrait::class.java) }
                    .map { ctx.symbolProvider.toMemberName(it.member) }
                    .toMutableSet()
            ).toMutableSet()

            val bodyMemberNames = bodyMembers
                .filter { !it.member.hasTrait(HttpQueryTrait::class.java) }
                .map { ctx.symbolProvider.toMemberName(it.member) }.toMutableSet()

            if (bodyMemberNames.isNotEmpty()) {
                writer.write("if case .data(let data) = httpResponse.body,")
                writer.indent()
                writer.write("let unwrappedData = data,")
                writer.write("let responseDecoder = decoder {")
                writer.write("let output: ${outputShapeName}Body = try responseDecoder.decode(responseBody: unwrappedData)")
                bodyMemberNames.sorted().forEach {
                    writer.write("self.$it = output.$it")
                }
                writer.dedent()
                writer.write("} else {")
                writer.indent()
                bodyMembers.sortedBy { it.memberName }.forEach {
                    val memberName = ctx.symbolProvider.toMemberName(it.member)
                    val type = ctx.model.expectShape(it.member.target)
                    val value = if (ctx.symbolProvider.toSymbol(it.member).isBoxed()) "nil" else {
                        when (type) {
                            is IntegerShape, is ByteShape, is ShortShape, is LongShape -> 0
                            is FloatShape, is DoubleShape -> 0.0
                            is BooleanShape -> false
                            else -> "nil"
                        }
                    }
                    writer.write("self.$memberName = $value")
                }
                writer.dedent()
                writer.write("}")
            }
        }

        queryMemberNames.sorted().forEach {
            writer.write("self.$it = nil")
        }

        val responseCodeTraitMembers = responseBindings
            .filter { it.member.hasTrait(HttpResponseCodeTrait::class.java) }
            .toMutableSet()
        if (responseCodeTraitMembers.isNotEmpty()) {
            responseCodeTraitMembers.forEach {
                writer.write("self.${it.locationName.decapitalize()} = httpResponse.statusCode.rawValue")
            }
        }
    }

    private fun renderDeserializeExplicitPayload(ctx: ProtocolGenerator.GenerationContext, binding: HttpBindingDescriptor, writer: SwiftWriter) {
        val memberName = ctx.symbolProvider.toMemberName(binding.member)
        val target = ctx.model.expectShape(binding.member.target)
        val symbol = ctx.symbolProvider.toSymbol(target)
        writer.openBlock("if case .data(let data) = httpResponse.body,\n   let unwrappedData = data {", "} else {") {
            when (target.type) {
                ShapeType.DOCUMENT -> {
                    writer.openBlock("if let responseDecoder = decoder {", "} else {") {
                        writer.write(
                            "let output: \$L = try responseDecoder.decode(responseBody: unwrappedData)",
                            symbol.name
                        )
                        writer.write("self.\$L = output", memberName)
                    }
                    writer.indent()
                    writer.write("self.\$L = nil", memberName).closeBlock("}")
                }
                ShapeType.STRING -> {
                    writer.openBlock("if let responseDecoder = decoder {", "} else {") {
                        writer.write(
                            "let output: \$L = try responseDecoder.decode(responseBody: unwrappedData)",
                            symbol
                        )
                        writer.write("self.\$L = output", memberName)
                    }
                    writer.indent()
                    writer.write("self.\$L = nil", memberName).closeBlock("}")
                }
                ShapeType.BLOB -> {
                    writer.write("self.\$L = unwrappedData", memberName)
                }
                ShapeType.STRUCTURE, ShapeType.UNION -> {
                    writer.openBlock("if let responseDecoder = decoder {", "} else {") {
                        writer.write(
                            "let output: \$L = try responseDecoder.decode(responseBody: unwrappedData)",
                            symbol
                        )
                        writer.write("self.\$L = output", memberName)
                    }
                    writer.indent()
                    writer.write("self.\$L = nil", memberName).closeBlock("}")
                }
                else -> throw CodegenException("member shape ${binding.member} serializer not implemented yet")
            }
        }
        writer.indent()
        writer.write("self.\$L = nil", memberName).closeBlock("}")
    }
}
