/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.traits.StreamingTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HTTPProtocolCustomizable
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.HTTPResponseBindingRenderable
import software.amazon.smithy.swift.codegen.integration.serde.member.MemberShapeDecodeGenerator
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.isEnum
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyEventStreamsTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyReadWriteTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes

class HTTPResponseTraitWithHTTPPayload(
    val ctx: ProtocolGenerator.GenerationContext,
    val binding: HttpBindingDescriptor,
    val writer: SwiftWriter,
    val shapeContainingMembers: Shape,
    val customizations: HTTPProtocolCustomizable,
) : HTTPResponseBindingRenderable {

    override fun render() {
        val memberName = ctx.symbolProvider.toMemberName(binding.member)
        val target = ctx.model.expectShape(binding.member.target)
        val symbol = ctx.symbolProvider.toSymbol(target)
        val isBinaryStream =
            ctx.model.getShape(binding.member.target).get().hasTrait<StreamingTrait>() && target.type == ShapeType.BLOB
        when (target.type) {
            ShapeType.DOCUMENT -> {
                writer.openBlock("if let data = try await httpResponse.body.readData() {", "}") {
                    writer.write("value.\$L = try \$N.make(from: data)", memberName, SmithyReadWriteTypes.Document)
                }
            }
            ShapeType.STRING -> {
                writer.openBlock("if let data = try await httpResponse.body.readData(), let output = \$N(data: data, encoding: .utf8) {", "}", SwiftTypes.String) {
                    if (target.isEnum) {
                        writer.write("value.\$L = \$L(rawValue: output)", memberName, symbol)
                    } else {
                        writer.write("value.\$L = output", memberName)
                    }
                }
            }
            ShapeType.ENUM -> {
                writer.openBlock("if let data = try await httpResponse.body.readData(), let output = \$N(data: data, encoding: .utf8) {", "}", SwiftTypes.String) {
                    writer.write("value.\$L = \$L(rawValue: output)", memberName, symbol)
                }
            }
            ShapeType.BLOB -> {
                writer.write("switch httpResponse.body {")
                    .write("case .data(let data):")
                    .indent()
                if (isBinaryStream) {
                    writer.write("value.\$L = .data(data)", memberName)
                } else {
                    writer.write("value.\$L = data", memberName)
                }

                // For binary streams, we need to set the member to the stream directly.
                // this allows us to stream the data directly to the user
                // without having to buffer it in memory.
                writer.dedent()
                    .write("case .stream(let stream):")
                    .indent()
                if (isBinaryStream) {
                    writer.write("value.\$L = .stream(stream)", memberName)
                } else {
                    writer.write("value.\$L = try stream.readToEnd()", memberName)
                }
                writer.dedent()
                    .write("case .noStream:")
                    .indent()
                    .write("value.\$L = nil", memberName).closeBlock("}")
            }
            ShapeType.STRUCTURE, ShapeType.UNION -> {
                if (target.hasTrait<StreamingTrait>()) {
                    writer.openBlock("if case .stream(let stream) = httpResponse.body {", "}") {
                        writer.write("let messageDecoder = \$N()", SmithyEventStreamsTypes.DefaultMessageDecoder)
                        writer.write(
                            "let decoderStream = \$N(stream: stream, messageDecoder: messageDecoder, unmarshalClosure: \$N.unmarshal)",
                            SmithyEventStreamsTypes.DefaultMessageDecoderStream,
                            symbol,
                        )
                        writer.write("value.\$L = decoderStream.toAsyncStream()", memberName)
                    }
                } else {
                    MemberShapeDecodeGenerator(ctx, writer, shapeContainingMembers)
                        .render(binding.member, true)
                }
            }
            else -> throw CodegenException("member shape ${binding.member} serializer not implemented yet")
        }
    }
}
