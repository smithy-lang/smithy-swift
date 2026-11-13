package software.amazon.smithy.swift.codegen.events

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.EventHeaderTrait
import software.amazon.smithy.model.traits.EventPayloadTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HTTPProtocolCustomizable
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.ReadingClosureUtils
import software.amazon.smithy.swift.codegen.integration.serde.struct.readerSymbol
import software.amazon.smithy.swift.codegen.model.eventStreamErrors
import software.amazon.smithy.swift.codegen.model.eventStreamEvents
import software.amazon.smithy.swift.codegen.model.expectShape
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyEventStreamsAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes
import software.amazon.smithy.swift.codegen.utils.SDKFileUtils

class MessageUnmarshallableGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
    val customizations: HTTPProtocolCustomizable,
) {
    // The smithy-swift unknown error has no request ID; other unknown error types, i.e. the AWS one,
    // require one.
    private val requestIDArg =
        ", requestID: nil".takeIf { customizations.unknownServiceErrorSymbol != ClientRuntimeTypes.Http.UnknownHttpServiceError } ?: ""

    fun render(streamingMember: MemberShape) {
        val symbol: Symbol = ctx.symbolProvider.toSymbol(ctx.model.expectShape(streamingMember.target))
        val filename = SDKFileUtils(ctx.settings).modelFilePath("${symbol.name}+MessageUnmarshallable")
        val streamMember =
            Symbol
                .builder()
                .definitionFile(filename)
                .name(symbol.name)
                .build()

        val streamShape = ctx.model.expectShape<UnionShape>(streamingMember.target)
        val streamSymbol = ctx.symbolProvider.toSymbol(streamShape)

        ctx.delegator.useShapeWriter(streamMember) { writer ->

            writer.openBlock("extension \$L {", "}", streamSymbol.fullName) {
                writer.openBlock(
                    "static var unmarshal: \$N<\$N> {",
                    "}",
                    SmithyEventStreamsAPITypes.UnmarshalClosure,
                    streamSymbol,
                ) {
                    writer.openBlock("{ message in", "}") {
                        writer.write("switch try message.type() {")
                        writer.write("case .event(let params):")
                        writer.indent {
                            writer.write("switch params.eventType {")
                            streamShape.eventStreamEvents(ctx.model).forEach { member ->
                                writer.write("case \"${member.memberName}\":")
                                writer.indent {
                                    renderDeserializeEventVariant(ctx, streamSymbol, member, writer)
                                }
                            }
                            writer.write("default:")
                            writer.indent {
                                writer.write(
                                    "return .sdkUnknown(\"error processing event stream, unrecognized event: \\(params.eventType)\")",
                                )
                            }
                            writer.write("}")
                        }
                        writer.write("case .exception(let params):")
                        writer.indent {
                            writer.write(
                                "let makeError: (\$N, \$N.ExceptionParams) throws -> \$N = { message, params in",
                                SmithyEventStreamsAPITypes.Message,
                                SmithyEventStreamsAPITypes.MessageType,
                                SwiftTypes.Error,
                            )
                            writer.indent {
                                writer.write("switch params.exceptionType {")
                                streamShape.eventStreamErrors(ctx.model).forEach { member ->
                                    writer.write("case \$S:", member.memberName)
                                    writer.indent {
                                        renderReadToValue(writer, member)
                                        writer.write("return value")
                                    }
                                }
                                writer.write("default:")
                                writer.indent {
                                    writer.write(
                                        "let httpResponse = \$N(body: .data(message.payload), statusCode: .ok)",
                                        SmithyHTTPAPITypes.HTTPResponse,
                                    )
                                    writer.write(
                                        "return \$N(httpResponse: httpResponse, message: \"error processing event stream, unrecognized ':exceptionType': \\(params.exceptionType); contentType: \\(params.contentType ?? \"nil\")\"\$L, typeName: nil)",
                                        customizations.unknownServiceErrorSymbol,
                                        requestIDArg,
                                    )
                                }
                                writer.write("}")
                            }
                            writer.write("}")
                            writer.write("let error = try makeError(message, params)")
                            writer.write("throw error")
                        }
                        writer.write("case .error(let params):")
                        writer.indent {
                            // this is a service exception still, just un-modeled
                            writer.write(
                                "let httpResponse = \$N(body: .data(message.payload), statusCode: .ok)",
                                SmithyHTTPAPITypes.HTTPResponse,
                            )
                            writer.write(
                                "throw \$N(httpResponse: httpResponse, message: \"error processing event stream, unrecognized ':errorType': \\(params.errorCode); message: \\(params.message ?? \"nil\")\"\$L, typeName: nil)",
                                customizations.unknownServiceErrorSymbol,
                                requestIDArg,
                            )
                        }
                        writer.write("case .unknown(messageType: let messageType):")
                        writer.indent {
                            // this is a client exception because we failed to parse it
                            writer.write(
                                "throw \$N.unknownError(\"unrecognized event stream message ':message-type': \\(messageType)\")",
                                SmithyTypes.ClientError,
                            )
                        }
                        writer.write("}")
                    }
                }
            }
        }
    }

    private fun renderDeserializeEventVariant(
        ctx: ProtocolGenerator.GenerationContext,
        unionSymbol: Symbol,
        member: MemberShape,
        writer: SwiftWriter,
    ) {
        val variant = ctx.model.expectShape(member.target)

        val eventHeaderBindings = variant.members().filter { it.hasTrait<EventHeaderTrait>() }
        val eventPayloadBinding = variant.members().firstOrNull { it.hasTrait<EventPayloadTrait>() }
        val unbound = variant.members().filterNot { it.hasTrait<EventHeaderTrait>() || it.hasTrait<EventPayloadTrait>() }
        val memberName = ctx.symbolProvider.toMemberName(member)

        if (eventHeaderBindings.isEmpty() && eventPayloadBinding == null) {
            renderReadToValue(writer, member)
            writer.write("return .\$L(value)", memberName)
        } else {
            val variantSymbol = ctx.symbolProvider.toSymbol(variant)
            writer.write("var event = \$N()", variantSymbol)
            // render members bound to header
            eventHeaderBindings.forEach { hdrBinding ->
                val target = ctx.model.expectShape(hdrBinding.target)

                val conversionFn =
                    when (target.type) {
                        ShapeType.BOOLEAN -> "bool"
                        ShapeType.BYTE -> "byte"
                        ShapeType.SHORT -> "int16"
                        ShapeType.INTEGER, ShapeType.INT_ENUM -> "int32"
                        ShapeType.LONG -> "int64"
                        ShapeType.BLOB -> "byteArray"
                        ShapeType.STRING, ShapeType.ENUM -> "string"
                        ShapeType.TIMESTAMP -> "timestamp"
                        else -> throw CodegenException("unsupported eventHeader shape: member=$hdrBinding; targetShape=$target")
                    }

                writer.openBlock("if case .\$L(let value) = message.headers.value(name: \$S) {", "}", conversionFn, hdrBinding.memberName) {
                    val memberName = ctx.symbolProvider.toMemberName(hdrBinding)
                    when (target.type) {
                        ShapeType.INTEGER, ShapeType.LONG -> {
                            writer.write("event.\$L = Int(value)", memberName)
                        }
                        ShapeType.INT_ENUM -> {
                            writer.write("event.\$L = .init(rawValue: Int(value))", memberName)
                        }
                        ShapeType.ENUM -> {
                            writer.write("event.\$L = .init(rawValue: value)", memberName)
                        }
                        else -> {
                            writer.write("event.\$L = value", memberName)
                        }
                    }
                }
            }

            if (eventPayloadBinding != null) {
                renderDeserializeExplicitEventPayloadMember(ctx, eventPayloadBinding, writer)
            } else {
                if (unbound.isNotEmpty()) {
                    // All remaining members are bound to the payload (but not explicitly bound via @eventPayload).
                    // The payload is a document for the overall event shape, containing only the unbound members.
                    // Read the payload as the event shape, then assign each unbound member to the event.
                    renderReadToValue(writer, member)
                    unbound.forEach {
                        val unboundMemberName = ctx.symbolProvider.toMemberName(it)
                        writer.write("event.\$L = value.\$L", unboundMemberName, unboundMemberName)
                    }
                }
            }
            writer.write("return .\$L(event)", memberName)
        }
    }

    private fun renderDeserializeExplicitEventPayloadMember(
        ctx: ProtocolGenerator.GenerationContext,
        member: MemberShape,
        writer: SwiftWriter,
    ) {
        val target = ctx.model.expectShape(member.target)
        val memberName = ctx.symbolProvider.toMemberName(member)
        when (target.type) {
            ShapeType.BLOB -> writer.write("event.\$L = message.payload", memberName)
            ShapeType.STRING -> writer.write("event.\$L = String(data: message.payload, encoding: .utf8)", memberName)
            ShapeType.STRUCTURE, ShapeType.UNION -> {
                renderReadToValue(writer, member)
                writer.write("event.\$L = value", ctx.symbolProvider.toMemberName(member))
            }
            else -> throw CodegenException(
                "unsupported shape type `${target.type}` for target: $target; expected blob, string, structure, or union for eventPayload member: $member",
            )
        }
    }

    private fun renderReadToValue(
        writer: SwiftWriter,
        memberShape: MemberShape,
    ) {
        val readingClosure = ReadingClosureUtils(ctx, writer).readingClosure(memberShape)
        writer.write(
            "let value = try \$N.readFrom(message.payload, with: \$L)",
            ctx.service.readerSymbol,
            readingClosure,
        )
    }
}
