/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.shapes.BooleanShape
import software.amazon.smithy.model.shapes.ByteShape
import software.amazon.smithy.model.shapes.DoubleShape
import software.amazon.smithy.model.shapes.FloatShape
import software.amazon.smithy.model.shapes.IntegerShape
import software.amazon.smithy.model.shapes.LongShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.shapes.ShortShape
import software.amazon.smithy.model.traits.HttpQueryTrait
import software.amazon.smithy.model.traits.StreamingTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.declareSection
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.HttpResponseBindingRenderable
import software.amazon.smithy.swift.codegen.model.isBoxed
import software.amazon.smithy.swift.codegen.model.targetOrSelf

interface HttpResponseTraitWithoutHttpPayloadFactory {
    fun construct(
        ctx: ProtocolGenerator.GenerationContext,
        responseBindings: List<HttpBindingDescriptor>,
        outputShapeName: String,
        writer: SwiftWriter
    ): HttpResponseBindingRenderable
}

class HttpResponseTraitWithoutHttpPayload(
    val ctx: ProtocolGenerator.GenerationContext,
    val responseBindings: List<HttpBindingDescriptor>,
    val outputShapeName: String,
    val writer: SwiftWriter
) : HttpResponseBindingRenderable {
    override fun render() {
        val bodyMembers = responseBindings.filter { it.location == HttpBinding.Location.DOCUMENT }
        val bodyMembersWithoutQueryTrait = bodyMembers
            .filter { !it.member.hasTrait(HttpQueryTrait::class.java) }
            .toMutableSet()
        val streamingMember = bodyMembers.firstOrNull { it.member.targetOrSelf(ctx.model).hasTrait(StreamingTrait::class.java) }

        if (streamingMember != null) {
            writeStreamingMember(streamingMember)
        } else if (bodyMembersWithoutQueryTrait.isNotEmpty()) {
            writeNonStreamingMembers(bodyMembersWithoutQueryTrait)
        }
    }

    fun writeStreamingMember(streamingMember: HttpBindingDescriptor) {
        val shape = ctx.model.expectShape(streamingMember.member.target)
        val symbol = ctx.symbolProvider.toSymbol(shape)
        val memberName = ctx.symbolProvider.toMemberName(streamingMember.member)
        when(shape.type) {
            ShapeType.UNION -> {
                writer.openBlock("if case let .stream(stream) = httpResponse.body, let responseDecoder = decoder {", "} else {") {
                    writer.declareSection(HttpResponseTraitWithHttpPayload.MessageDecoderSectionId) {
                        writer.write("let messageDecoder: \$D", ClientRuntimeTypes.EventStream.MessageDecoder)
                    }
                    writer.write(
                        "let decoderStream = \$L<\$N>(stream: stream, messageDecoder: messageDecoder, responseDecoder: responseDecoder)",
                        ClientRuntimeTypes.EventStream.MessageDecoderStream,
                        symbol
                    )
                    writer.write("self.\$L = decoderStream.toAsyncStream()", memberName)
                }
                writer.indent()
                writer.write("self.\$L = nil", memberName).closeBlock("}")
            }
            ShapeType.BLOB -> {
                writer.write("switch httpResponse.body {")
                    .write("case .data(let data):")
                    .indent()
                writer.write("self.\$L = .data(data)", memberName)

                // For binary streams, we need to set the member to the stream directly.
                // this allows us to stream the data directly to the user
                // without having to buffer it in memory.
                writer.dedent()
                    .write("case .stream(let stream):")
                    .indent()
                writer.write("self.\$L = .stream(stream)", memberName)
                writer.dedent()
                    .write("case .none:")
                    .indent()
                    .write("self.\$L = nil", memberName).closeBlock("}")
            }
            else -> {
                throw CodegenException("member shape ${streamingMember.member} cannot stream")
            }
        }
    }

    fun writeNonStreamingMembers(members: Set<HttpBindingDescriptor>) {
        val memberNames = members.map { ctx.symbolProvider.toMemberName(it.member) }
        writer.write("if let data = try httpResponse.body.toData(),")
        writer.indent()
        writer.write("let responseDecoder = decoder {")
        writer.write("let output: ${outputShapeName}Body = try responseDecoder.decode(responseBody: data)")
        memberNames.sorted().forEach {
            writer.write("self.$it = output.$it")
        }
        writer.dedent()
        writer.write("} else {")
        writer.indent()
        members.sortedBy { it.memberName }.forEach {
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
