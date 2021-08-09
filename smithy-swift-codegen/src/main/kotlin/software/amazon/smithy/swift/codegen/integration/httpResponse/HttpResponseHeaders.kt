package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.shapes.BlobShape
import software.amazon.smithy.model.shapes.BooleanShape
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.NumberShape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.MediaTypeTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.isBoxed

class HttpResponseHeaders(
    val ctx: ProtocolGenerator.GenerationContext,
    val bindings: List<HttpBindingDescriptor>,
    val defaultTimestampFormat: TimestampFormatTrait.Format,
    val writer: SwiftWriter
) {
    fun render() {
        bindings.forEach { hdrBinding ->
            val memberTarget = ctx.model.expectShape(hdrBinding.member.target)
            val memberName = ctx.symbolProvider.toMemberName(hdrBinding.member)
            val headerName = hdrBinding.locationName
            val headerDeclaration = "${memberName}HeaderValue"
            val isBoxed = ctx.symbolProvider.toSymbol(memberTarget).isBoxed()
            writer.write("if let $headerDeclaration = httpResponse.headers.value(for: \$S) {", headerName)
            writer.indent()
            when (memberTarget) {
                is NumberShape -> {
                    val memberValue = stringToNumber(memberTarget, headerDeclaration)
                    writer.write("self.\$L = $memberValue", memberName)
                }
                is BlobShape -> {
                    val memberValue = "$headerDeclaration.data(using: .utf8)"
                    writer.write("self.\$L = $memberValue", memberName)
                }
                is BooleanShape -> {
                    val memberValue = "${SwiftTypes.Bool.fullName}($headerDeclaration) ?? false"
                    writer.write("self.\$L = $memberValue", memberName)
                }
                is StringShape -> {
                    val memberValue = when {
                        memberTarget.hasTrait<EnumTrait>() -> {
                            val enumSymbol = ctx.symbolProvider.toSymbol(memberTarget)
                            "${enumSymbol.fullName}(rawValue: $headerDeclaration)"
                        }
                        memberTarget.hasTrait<MediaTypeTrait>() -> {
                            "try $headerDeclaration.base64DecodedString()"
                        }
                        else -> {
                            headerDeclaration
                        }
                    }
                    writer.write("self.\$L = $memberValue", memberName)
                }
                is TimestampShape -> {
                    val bindingIndex = HttpBindingIndex.of(ctx.model)
                    val tsFormat = bindingIndex.determineTimestampFormat(
                        hdrBinding.member,
                        HttpBinding.Location.HEADER,
                        defaultTimestampFormat
                    )
                    var memberValue = stringToDate(headerDeclaration, tsFormat)
                    if (tsFormat == TimestampFormatTrait.Format.EPOCH_SECONDS) {
                        memberValue = stringToDate("${headerDeclaration}Double", tsFormat)
                        writer.write("if let ${headerDeclaration}Double = \$N(\$LHeaderValue) {", SwiftTypes.Double, memberName)
                        writer.indent()
                        writer.write("self.\$L = $memberValue", memberName)
                        writer.dedent()
                        writer.write("} else {")
                        writer.indent()
                        writer.write("throw \$T.deserializationFailed(HeaderDeserializationError.invalidTimestampHeader(value: \$LHeaderValue))", ClientRuntimeTypes.Core.ClientError, memberName)
                        writer.dedent()
                        writer.write("}")
                    } else {
                        writer.write("self.\$L = $memberValue", memberName)
                    }
                }
                is CollectionShape -> {
                    // member > boolean, number, string, or timestamp
                    // headers are List<String>, get the internal mapping function contents (if any) to convert
                    // to the target symbol type

                    // we also have to handle multiple comma separated values (e.g. 'X-Foo': "1, 2, 3"`)
                    var splitFn = "splitHeaderListValues"
                    var splitFnPrefix = ""
                    var invalidHeaderListErrorName = "invalidNumbersHeaderList"
                    val conversion = when (val collectionMemberTarget = ctx.model.expectShape(memberTarget.member.target)) {
                        is BooleanShape -> {
                            invalidHeaderListErrorName = "invalidBooleanHeaderList"
                            "${SwiftTypes.Bool.fullName}(\$0)"
                        }
                        is NumberShape -> "(${stringToNumber(collectionMemberTarget, "\$0")} ?? 0)"
                        is TimestampShape -> {
                            val bindingIndex = HttpBindingIndex.of(ctx.model)
                            val tsFormat = bindingIndex.determineTimestampFormat(
                                hdrBinding.member,
                                HttpBinding.Location.HEADER,
                                defaultTimestampFormat
                            )
                            if (tsFormat == TimestampFormatTrait.Format.HTTP_DATE) {
                                splitFn = "splitHttpDateHeaderListValues"
                                splitFnPrefix = "try "
                            }
                            invalidHeaderListErrorName = "invalidTimestampHeaderList"
                            "(${stringToDate("\$0", tsFormat)} ?? ${ClientRuntimeTypes.Core.Date.fullName}())"
                        }
                        is StringShape -> {
                            invalidHeaderListErrorName = "invalidStringHeaderList"
                            when {
                                collectionMemberTarget.hasTrait<EnumTrait>() -> {
                                    val enumSymbol = ctx.symbolProvider.toSymbol(collectionMemberTarget)
                                    "(${enumSymbol.fullName}(rawValue: \$0) ?? ${enumSymbol.fullName}(rawValue: \"Bar\")!)"
                                }
                                collectionMemberTarget.hasTrait<MediaTypeTrait>() -> {
                                    "try \$0.base64EncodedString()"
                                }
                                else -> ""
                            }
                        }
                        else -> throw CodegenException("invalid member type for header collection: binding: $hdrBinding; member: $memberName")
                    }
                    val mapFn = if (conversion.isNotEmpty()) ".map { $conversion }" else ""
                    var memberValue = "${memberName}HeaderValues$mapFn"
                    if (memberTarget.isSetShape) {
                        memberValue = "${SwiftTypes.Set.fullName}(${memberName}HeaderValues)"
                    }
                    writer.write("if let ${memberName}HeaderValues = $splitFnPrefix$splitFn(${memberName}HeaderValue) {")
                    writer.indent()
                    // render map function
                    val collectionMemberTargetShape = ctx.model.expectShape(memberTarget.member.target)
                    val collectionMemberTargetSymbol = ctx.symbolProvider.toSymbol(collectionMemberTargetShape)
                    if (!collectionMemberTargetSymbol.isBoxed()) {
                        writer.openBlock("self.\$L = try \$LHeaderValues.map {", "}", memberName, memberName) {
                            val transformedHeaderDeclaration = "${memberName}Transformed"
                            writer.openBlock("guard let \$L = \$L else {", "}", transformedHeaderDeclaration, conversion) {
                                writer.write("throw \$T.deserializationFailed(HeaderDeserializationError.\$L(value: \$LHeaderValue))", ClientRuntimeTypes.Core.ClientError, invalidHeaderListErrorName, memberName)
                            }
                            writer.write("return \$L", transformedHeaderDeclaration)
                        }
                    } else {
                        writer.write("self.\$L = \$L", memberName, memberValue)
                    }
                    writer.dedent()
                    writer.write("} else {")
                    writer.indent()
                    writer.write("self.\$L = nil", memberName)
                    writer.dedent()
                    writer.write("}")
                }
                else -> throw CodegenException("unknown deserialization: header binding: $hdrBinding; member: `$memberName`")
            }
            writer.dedent()
            writer.write("} else {")
            writer.indent()
            var assignmentValue = "nil"
            when (memberTarget) {
                is NumberShape -> {
                    assignmentValue = if (isBoxed) "nil" else "0"
                }
                is BooleanShape -> {
                    assignmentValue = if (isBoxed) "nil" else "false"
                }
            }
            writer.write("self.$memberName = $assignmentValue")
            writer.dedent()
            writer.write("}")
        }
    }

    private fun stringToNumber(shape: NumberShape, stringValue: String): String = when (shape.type) {
        ShapeType.BYTE -> "${SwiftTypes.Int8.fullName}($stringValue) ?? 0"
        ShapeType.SHORT -> "${SwiftTypes.Int16.fullName}($stringValue) ?? 0"
        ShapeType.INTEGER -> "${SwiftTypes.Int.fullName}($stringValue) ?? 0"
        ShapeType.LONG -> "${SwiftTypes.Int.fullName}($stringValue) ?? 0"
        ShapeType.FLOAT -> "${SwiftTypes.Float.fullName}($stringValue) ?? 0"
        ShapeType.DOUBLE -> "${SwiftTypes.Double.fullName}($stringValue) ?? 0"
        else -> throw CodegenException("unknown number shape: $shape")
    }

    private fun stringToDate(stringValue: String, tsFmt: TimestampFormatTrait.Format): String = when (tsFmt) {
        TimestampFormatTrait.Format.EPOCH_SECONDS -> "${ClientRuntimeTypes.Core.Date.fullName}(timeIntervalSince1970: $stringValue)"
        TimestampFormatTrait.Format.DATE_TIME -> "DateFormatter.iso8601DateFormatterWithoutFractionalSeconds.date(from: $stringValue)"
        TimestampFormatTrait.Format.HTTP_DATE -> "DateFormatter.rfc5322DateFormatter.date(from: $stringValue)"
        else -> throw CodegenException("unknown timestamp format: $tsFmt")
    }
}
