/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.traits.StreamingTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HTTPProtocolCustomizable
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.HTTPResponseBindingRenderable
import software.amazon.smithy.swift.codegen.integration.serde.member.MemberShapeDecodeGenerator
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.isRPCBound
import software.amazon.smithy.swift.codegen.model.targetOrSelf

class HTTPResponseTraitWithoutHTTPPayload(
    val ctx: ProtocolGenerator.GenerationContext,
    val responseBindings: List<HttpBindingDescriptor>,
    val outputShape: Shape,
    val writer: SwiftWriter,
    val customizations: HTTPProtocolCustomizable,
) : HTTPResponseBindingRenderable {
    override fun render() {
        val bodyMembers = responseBindings.filter { it.location == HttpBinding.Location.DOCUMENT }.toSet()
        val streamingMember = bodyMembers.firstOrNull { it.member.targetOrSelf(ctx.model).hasTrait(StreamingTrait::class.java) }
        if (streamingMember != null) {
            val initialResponseMembers = bodyMembers.filter {
                val targetShape = it.member.targetOrSelf(ctx.model)
                targetShape?.hasTrait(StreamingTrait::class.java) == false
            }.toSet()
            writeStreamingMember(streamingMember, initialResponseMembers)
        } else {
            writeNonStreamingMembers(bodyMembers)
        }
    }

    fun writeStreamingMember(streamingMember: HttpBindingDescriptor, initialResponseMembers: Set<HttpBindingDescriptor>) {
        val shape = ctx.model.expectShape(streamingMember.member.target)
        val symbol = ctx.symbolProvider.toSymbol(shape)
        val memberName = ctx.symbolProvider.toMemberName(streamingMember.member)
        when (shape.type) {
            ShapeType.UNION -> {
                writer.openBlock("if case let .stream(stream) = httpResponse.body {", "}") {
                    writer.addImport(customizations.messageDecoderSymbol.namespace)
                    writer.write("let messageDecoder = \$N()", customizations.messageDecoderSymbol)
                    writer.write(
                        "let decoderStream = \$L<\$N>(stream: stream, messageDecoder: messageDecoder, unmarshalClosure: \$N.unmarshal)",
                        ClientRuntimeTypes.EventStream.MessageDecoderStream,
                        symbol,
                        symbol,
                    )
                    writer.write("value.\$L = decoderStream.toAsyncStream()", memberName)
                    if (ctx.service.isRPCBound && initialResponseMembers.isNotEmpty()) {
                        writeInitialResponseMembers(initialResponseMembers)
                    }
                }
            }
            ShapeType.BLOB -> {
                writer.write("switch httpResponse.body {")
                    .write("case .data(let data):")
                    .indent()
                writer.write("value.\$L = .data(data)", memberName)

                // For binary streams, we need to set the member to the stream directly.
                // this allows us to stream the data directly to the user
                // without having to buffer it in memory.
                writer.dedent()
                    .write("case .stream(let stream):")
                    .indent()
                writer.write("value.\$L = .stream(stream)", memberName)
                writer.dedent()
                    .write("case .noStream:")
                    .indent()
                    .write("value.\$L = nil", memberName).closeBlock("}")
            }
            else -> {
                throw CodegenException("member shape ${streamingMember.member} cannot stream")
            }
        }
    }

    fun writeNonStreamingMembers(members: Set<HttpBindingDescriptor>) {
        members.sortedBy { it.memberName }.forEach {
            MemberShapeDecodeGenerator(ctx, writer, outputShape).render(it.member)
        }
    }

    private fun writeInitialResponseMembers(initialResponseMembers: Set<HttpBindingDescriptor>) {
        writer.openBlock(
            "if let initialDataWithoutHttp = await messageDecoder.awaitInitialResponse() {",
            "}"
        ) {
            writer.write("let payloadReader = try Reader.from(data: initialDataWithoutHttp)")
            initialResponseMembers.forEach { responseMember ->
                val responseMemberName = ctx.symbolProvider.toMemberName(responseMember.member)
                writer.write(
                    "value.\$L = try payloadReader[\$S].readIfPresent()",
                    responseMemberName,
                    responseMemberName,
                )
            }
        }
    }
}
