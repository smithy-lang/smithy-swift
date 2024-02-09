/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.traits.StreamingTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.declareSection
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SectionId
import software.amazon.smithy.swift.codegen.integration.httpResponse.HttpResponseBindingRenderable
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.isEnum

class HttpResponseTraitWithHttpPayload(
    val ctx: ProtocolGenerator.GenerationContext,
    val binding: HttpBindingDescriptor,
    val writer: SwiftWriter
) : HttpResponseBindingRenderable {

    object MessageDecoderSectionId : SectionId

    override fun render() {
        val memberName = ctx.symbolProvider.toMemberName(binding.member)
        val target = ctx.model.expectShape(binding.member.target)
        val symbol = ctx.symbolProvider.toSymbol(target)
        val isBinaryStream =
            ctx.model.getShape(binding.member.target).get().hasTrait<StreamingTrait>() && target.type == ShapeType.BLOB
        when (target.type) {
            ShapeType.DOCUMENT -> {
                writer.openBlock("if let data = try await httpResponse.body.readData(), let responseDecoder = decoder {", "} else {") {
                    writer.write(
                        "let output: \$N = try responseDecoder.decode(responseBody: data)",
                        symbol
                    )
                    writer.write("self.\$L = output", memberName)
                }
                writer.indent()
                writer.write("self.\$L = nil", memberName).closeBlock("}")
            }
            ShapeType.STRING -> {
                writer.openBlock("if let data = try await httpResponse.body.readData(), let output = \$N(data: data, encoding: .utf8) {", "} else {", SwiftTypes.String) {
                    if (target.isEnum) {
                        writer.write("self.\$L = \$L(rawValue: output)", memberName, symbol)
                    } else {
                        writer.write("self.\$L = output", memberName)
                    }
                }
                writer.indent()
                writer.write("self.\$L = nil", memberName).closeBlock("}")
            }
            ShapeType.ENUM -> {
                writer.openBlock("if let data = try await httpResponse.body.readData(), let output = \$N(data: data, encoding: .utf8) {", "} else {", SwiftTypes.String) {
                    writer.write("self.\$L = \$L(rawValue: output)", memberName, symbol)
                }
                writer.indent()
                writer.write("self.\$L = nil", memberName).closeBlock("}")
            }
            ShapeType.BLOB -> {
                writer.write("switch await httpResponse.body {")
                    .write("case .data(let data):")
                    .indent()
                if (isBinaryStream) {
                    writer.write("self.\$L = .data(data)", memberName)
                } else {
                    writer.write("self.\$L = data", memberName)
                }

                // For binary streams, we need to set the member to the stream directly.
                // this allows us to stream the data directly to the user
                // without having to buffer it in memory.
                writer.dedent()
                    .write("case .stream(let stream):")
                    .indent()
                if (isBinaryStream) {
                    writer.write("self.\$L = .stream(stream)", memberName)
                } else {
                    writer.write("self.\$L = try stream.readToEnd()", memberName)
                }
                writer.dedent()
                    .write("case .noStream:")
                    .indent()
                    .write("self.\$L = nil", memberName).closeBlock("}")
            }
            ShapeType.STRUCTURE, ShapeType.UNION -> {
                if (target.hasTrait<StreamingTrait>()) {
                    writer.openBlock("if case let .stream(stream) = await httpResponse.body, let responseDecoder = decoder {", "} else {") {
                        writer.declareSection(MessageDecoderSectionId) {
                            writer.write("let messageDecoder: \$D", ClientRuntimeTypes.EventStream.MessageDecoder)
                        }
                        writer.write("let decoderStream = \$L<\$N>(stream: stream, messageDecoder: messageDecoder, responseDecoder: responseDecoder)", ClientRuntimeTypes.EventStream.MessageDecoderStream, symbol)
                        writer.write("self.\$L = decoderStream.toAsyncStream()", memberName)
                    }
                } else {
                    writer.openBlock("if let data = try await httpResponse.body.readData(), let responseDecoder = decoder {", "} else {") {
                        writer.write("let output: \$N = try responseDecoder.decode(responseBody: data)", symbol)
                        writer.write("self.\$L = output", memberName)
                    }
                }
                writer.indent()
                writer.write("self.\$L = nil", memberName).closeBlock("}")
            }
            else -> throw CodegenException("member shape ${binding.member} serializer not implemented yet")
        }
    }
}
