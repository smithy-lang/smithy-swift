package software.amazon.smithy.swift.codegen.events

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.EventHeaderTrait
import software.amazon.smithy.model.traits.EventPayloadTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.NodeInfoUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.WritingClosureUtils
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.requestWireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.responseWireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.struct.writerSymbol
import software.amazon.smithy.swift.codegen.model.eventStreamErrors
import software.amazon.smithy.swift.codegen.model.eventStreamEvents
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.swiftmodules.FoundationTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyEventStreamsAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes
import software.amazon.smithy.swift.codegen.utils.SDKFileUtils

class MessageMarshallableGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val payloadContentType: String,
) {
    internal fun render(streamShape: UnionShape) {
        val streamSymbol: Symbol = ctx.symbolProvider.toSymbol(streamShape)
        val filename = SDKFileUtils(ctx.settings).modelFilePath("${streamSymbol.name}+MessageMarshallable")
        val streamMember =
            Symbol
                .builder()
                .definitionFile(filename)
                .name(streamSymbol.name)
                .build()
        ctx.delegator.useShapeWriter(streamMember) { writer ->
            writer.apply {
                openBlock("extension \$L {", "}", streamSymbol.fullName) {
                    openBlock(
                        "static var marshal: \$N<\$N> {",
                        "}",
                        SmithyEventStreamsAPITypes.MarshalClosure,
                        streamSymbol,
                    ) {
                        openBlock("{ (self) in", "}") {
                            write(
                                "var headers: [\$N] = [.init(name: \":message-type\", value: .string(\"event\"))]",
                                SmithyEventStreamsAPITypes.Header,
                            )
                            write("var payload: \$D", FoundationTypes.Data)
                            write("switch self {")
                            streamShape.eventStreamEvents(ctx.model).forEach { member ->
                                val memberName = ctx.symbolProvider.toMemberName(member)
                                val variant = ctx.model.expectShape(member.target)

                                // Write the enum case for this event type.
                                // Unbound, header-bound, and payload-bound members require access to
                                // the event value for serialization, so unwrap value when
                                // those members exist.  The actual members will be written below.
                                val eventHeaderBindings =
                                    variant.members().filter {
                                        it.hasTrait<EventHeaderTrait>()
                                    }
                                val eventPayloadBinding =
                                    variant.members().firstOrNull {
                                        it.hasTrait<EventPayloadTrait>()
                                    }
                                val unbound =
                                    variant.members().filterNot {
                                        it.hasTrait<EventHeaderTrait>() || it.hasTrait<EventPayloadTrait>()
                                    }
                                if (unbound.isNotEmpty() || eventHeaderBindings.isNotEmpty() || eventPayloadBinding != null) {
                                    write("case .\$L(let value):", memberName)
                                } else {
                                    write("case .\$L:", memberName)
                                }
                                indent()

                                // Write the event headers to the message.  First write the
                                // event type, followed by header-bound members.
                                addStringHeader(":event-type", member.memberName)
                                renderEventContent(writer, member, "value")
                                writer.dedent()
                            }
                            writer.write("case .sdkUnknown(_):")
                            writer.indent()
                            writer.write(
                                "throw \$N.unknownError(\"cannot serialize the unknown event type!\")",
                                SmithyTypes.ClientError,
                            )
                            writer.dedent()
                            writer.write("}")
                            writer.write(
                                "return \$N(headers: headers, payload: payload ?? .init())",
                                SmithyEventStreamsAPITypes.Message,
                            )
                        }
                    }
                    write("")
                    renderMarshalError(writer, streamShape)
                }
            }
        }
    }

    /**
     * Renders a closure that marshals a modeled error on the event stream to an exception message.
     *
     * Modeled errors are not cases of the Swift event stream enum; a client sends one by finishing
     * its event stream with the error.  The closure returns `nil` for an error that is not modeled.
     */
    private fun renderMarshalError(
        writer: SwiftWriter,
        streamShape: UnionShape,
    ) {
        writer.openBlock(
            "static var marshalError: (any \$N) throws -> \$N? {",
            "}",
            SwiftTypes.Error,
            SmithyEventStreamsAPITypes.Message,
        ) {
            val errors = streamShape.eventStreamErrors(ctx.model)
            if (errors.isEmpty()) {
                writer.write("{ _ in nil }")
                return@openBlock
            }
            writer.openBlock("{ error in", "}") {
                writer.write(
                    "var headers: [\$N] = [.init(name: \":message-type\", value: .string(\"exception\"))]",
                    SmithyEventStreamsAPITypes.Header,
                )
                writer.write("var payload: \$D", FoundationTypes.Data)
                writer.write("switch error {")
                errors.forEach { member ->
                    writer.write("case let value as \$N:", ctx.symbolProvider.toSymbol(ctx.model.expectShape(member.target)))
                    writer.indent()
                    writer.addStringHeader(":exception-type", member.memberName)
                    renderEventContent(writer, member, "value.properties")
                    writer.dedent()
                }
                writer.write("default:")
                writer.indent()
                writer.write("return nil")
                writer.dedent()
                writer.write("}")
                writer.write("return \$N(headers: headers, payload: payload ?? .init())", SmithyEventStreamsAPITypes.Message)
            }
        }
    }

    /**
     * Renders the headers and payload of an event or error, from its members.
     *
     * @param member the member of the event stream union that targets the event or error
     * @param valuePath the Swift expression for the value holding the event's or error's members
     */
    private fun renderEventContent(
        writer: SwiftWriter,
        member: MemberShape,
        valuePath: String,
    ) {
        val variant = ctx.model.expectShape(member.target)
        val eventHeaderBindings = variant.members().filter { it.hasTrait<EventHeaderTrait>() }
        val eventPayloadBinding = variant.members().firstOrNull { it.hasTrait<EventPayloadTrait>() }
        val unbound = variant.members().filterNot { it.hasTrait<EventHeaderTrait>() || it.hasTrait<EventPayloadTrait>() }

        eventHeaderBindings.forEach {
            renderSerializeEventHeader(ctx, it, writer, valuePath)
        }

        // Write either the payload or the unbound members (there won't be both,
        // according to the Smithy spec: https://smithy.io/2.0/spec/streaming.html#eventpayload-trait.)
        when {
            eventPayloadBinding != null -> renderSerializeEventPayload(ctx, eventPayloadBinding, writer, valuePath)
            unbound.isNotEmpty() -> {
                writer.addStringHeader(":content-type", payloadContentType)
                val nodeInfo = NodeInfoUtils(ctx, writer, ctx.service.requestWireProtocol).nodeInfo(member, true)
                writer.write("let writer = \$N(nodeInfo: \$L)", ctx.service.writerSymbol, nodeInfo)
                unbound.forEach {
                    val writingClosure = WritingClosureUtils(ctx, writer).writingClosure(ctx.model.expectShape(it.target))
                    writer.write(
                        "try writer[\$S].write(\$L.\$L, with: \$L)",
                        it.memberName,
                        valuePath,
                        ctx.symbolProvider.toMemberName(it),
                        writingClosure,
                    )
                }
                writer.write("payload = try writer.data()")
            }
        }
    }

    private fun renderSerializeEventPayload(
        ctx: ProtocolGenerator.GenerationContext,
        member: MemberShape,
        writer: SwiftWriter,
        valuePath: String,
    ) {
        val target = ctx.model.expectShape(member.target)
        val memberName = ctx.symbolProvider.toMemberName(member)
        when (target.type) {
            ShapeType.BLOB -> {
                writer.addStringHeader(":content-type", "application/octet-stream")
                writer.write("payload = \$L.\$L", valuePath, memberName)
            }
            ShapeType.STRING -> {
                writer.addStringHeader(":content-type", "text/plain")
                writer.write("payload = \$L.\$L?.data(using: .utf8)", valuePath, memberName)
            }
            ShapeType.STRUCTURE, ShapeType.UNION -> {
                writer.addStringHeader(":content-type", payloadContentType)
                renderPayloadSerialization(ctx, writer, member, valuePath)
            }
            else -> throw CodegenException(
                "unsupported shape type `${target.type}` for target: $target; expected blob, string, structure, or union for eventPayload member: $member",
            )
        }
    }

    private fun renderSerializeEventHeader(
        ctx: ProtocolGenerator.GenerationContext,
        member: MemberShape,
        writer: SwiftWriter,
        valuePath: String,
    ) {
        val target = ctx.model.expectShape(member.target)
        val headerValue =
            when (target.type) {
                ShapeType.BOOLEAN -> "bool"
                ShapeType.BYTE -> "byte"
                ShapeType.SHORT -> "int16"
                ShapeType.INTEGER, ShapeType.INT_ENUM -> "int32"
                ShapeType.LONG -> "int64"
                ShapeType.BLOB -> "byteArray"
                ShapeType.STRING, ShapeType.ENUM -> "string"
                ShapeType.TIMESTAMP -> "timestamp"
                else -> throw CodegenException("unsupported shape type `${target.type}` for eventHeader member `$member`; target: $target")
            }

        val memberName = ctx.symbolProvider.toMemberName(member)
        writer.openBlock("if let headerValue = \$L.\$L {", "}", valuePath, memberName) {
            when (target.type) {
                ShapeType.INTEGER -> {
                    writer.write("headers.append(.init(name: \"${member.memberName}\", value: .\$L(Int32(headerValue))))", headerValue)
                }
                ShapeType.INT_ENUM -> {
                    writer.write(
                        "headers.append(.init(name: \$S, value: .\$L(Int32(headerValue.rawValue))))",
                        member.memberName,
                        headerValue,
                    )
                }
                ShapeType.LONG -> {
                    writer.write("headers.append(.init(name: \"${member.memberName}\", value: .\$L(Int64(headerValue))))", headerValue)
                }
                ShapeType.ENUM -> {
                    writer.write(
                        "headers.append(.init(name: \$S, value: .\$L(headerValue.rawValue)))",
                        member.memberName,
                        headerValue,
                    )
                }
                else -> {
                    writer.write("headers.append(.init(name: \"${member.memberName}\", value: .\$L(headerValue)))", headerValue)
                }
            }
        }
    }

    private fun SwiftWriter.addStringHeader(
        name: String,
        value: String,
    ) {
        write("headers.append(.init(name: \$S, value: .string(\$S)))", name, value)
    }

    private fun renderPayloadSerialization(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        memberShape: MemberShape,
        valuePath: String,
    ) {
        // get a payload serializer for the given members of the variant
        val nodeInfoUtils = NodeInfoUtils(ctx, writer, ctx.service.responseWireProtocol)
        val rootNodeInfo = nodeInfoUtils.nodeInfo(memberShape, true)
        val valueWritingClosure = WritingClosureUtils(ctx, writer).writingClosure(memberShape)
        writer.write(
            "payload = try \$N.write(\$L.\$L, rootNodeInfo: \$L, with: \$L)",
            ctx.service.writerSymbol,
            valuePath,
            ctx.symbolProvider.toMemberName(memberShape),
            rootNodeInfo,
            valueWritingClosure,
        )
    }
}
