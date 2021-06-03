package software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.HttpResponseBindingRenderable
import software.amazon.smithy.swift.codegen.model.isEnum

class HttpResponseTraitWithHttpPayload(
    val ctx: ProtocolGenerator.GenerationContext,
    val binding: HttpBindingDescriptor,
    val writer: SwiftWriter
) : HttpResponseBindingRenderable {
    override fun render() {
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
                    writer.openBlock("if let output = String(data: unwrappedData, encoding: .utf8) {", "} else {") {
                        if (target.isEnum) {
                            writer.write("self.\$L = \$L(rawValue: output)", memberName, symbol)
                        } else {
                            writer.write("self.\$L = output", memberName)
                        }
                    }
                    writer.indent()
                    writer.write("self.\$L = nil", memberName).closeBlock("}")
                }
                ShapeType.BLOB -> {
                    writer.write("self.\$L = unwrappedData", memberName)
                }
                ShapeType.UNION -> {
                    writer.openBlock("if let rawValue = String(data: unwrappedData, encoding: .utf8) {", "} else {") {
                        writer.write("self.\$L = \$L(rawValue: rawValue)", memberName, symbol)
                    }
                    writer.indent()
                    writer.write("self.\$L = nil", memberName).closeBlock("}")
                }
                ShapeType.STRUCTURE -> {
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
