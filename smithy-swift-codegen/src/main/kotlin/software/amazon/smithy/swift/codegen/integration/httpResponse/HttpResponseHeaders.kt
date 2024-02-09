/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.knowledge.HttpBinding
import software.amazon.smithy.model.knowledge.HttpBindingIndex
import software.amazon.smithy.model.shapes.BlobShape
import software.amazon.smithy.model.shapes.BooleanShape
import software.amazon.smithy.model.shapes.ListShape
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
import software.amazon.smithy.swift.codegen.integration.serde.TimestampHelpers
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.isBoxed

class HttpResponseHeaders(
    val ctx: ProtocolGenerator.GenerationContext,
    val error: Boolean,
    val bindings: List<HttpBindingDescriptor>,
    val defaultTimestampFormat: TimestampFormatTrait.Format,
    val writer: SwiftWriter
) {
    fun render() {
        bindings.forEach { hdrBinding ->
            val memberTarget = ctx.model.expectShape(hdrBinding.member.target)
            val path = "properties.".takeIf { error } ?: ""
            val memberName = ctx.symbolProvider.toMemberName(hdrBinding.member)
            val headerName = hdrBinding.locationName
            val headerDeclaration = "${memberName}HeaderValue"
            val isBoxed = ctx.symbolProvider.toSymbol(hdrBinding.member).isBoxed()
            writer.write("if let $headerDeclaration = await httpResponse.headers.value(for: \$S) {", headerName)
            writer.indent()
            when (memberTarget) {
                is NumberShape -> {
                    if (memberTarget.isIntEnumShape) {
                        val enumSymbol = ctx.symbolProvider.toSymbol(memberTarget)
                        writer.write(
                            "self.$path\$L = \$L(rawValue: \$L(\$L) ?? 0)",
                            memberName, enumSymbol, SwiftTypes.Int, headerDeclaration
                        )
                    } else {
                        val memberValue = stringToNumber(memberTarget, headerDeclaration, true)
                        writer.write("self.$path\$L = \$L", memberName, memberValue)
                    }
                }
                is BlobShape -> {
                    val memberValue = "$headerDeclaration.data(using: .utf8)"
                    writer.write("self.$path\$L = $memberValue", memberName)
                }
                is BooleanShape -> {
                    val memberValue = "${SwiftTypes.Bool}($headerDeclaration) ?? false"
                    writer.write("self.$path\$L = $memberValue", memberName)
                }
                is StringShape -> {
                    val memberValue = when {
                        memberTarget.hasTrait<EnumTrait>() -> {
                            val enumSymbol = ctx.symbolProvider.toSymbol(memberTarget)
                            "$enumSymbol(rawValue: $headerDeclaration)"
                        }
                        memberTarget.hasTrait<MediaTypeTrait>() -> {
                            "try $headerDeclaration.base64DecodedString()"
                        }
                        else -> {
                            headerDeclaration
                        }
                    }
                    writer.write("self.$path\$L = $memberValue", memberName)
                }
                is TimestampShape -> {
                    val bindingIndex = HttpBindingIndex.of(ctx.model)
                    val tsFormat = bindingIndex.determineTimestampFormat(
                        hdrBinding.member,
                        HttpBinding.Location.HEADER,
                        defaultTimestampFormat
                    )
                    var memberValue = stringToDate(headerDeclaration, tsFormat)
                    writer.write("self.$path\$L = \$L", memberName, memberValue)
                }
                is ListShape -> {
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
                            "${SwiftTypes.Bool}(\$0)"
                        }
                        is NumberShape -> {
                            if (collectionMemberTarget.isIntEnumShape) {
                                val enumSymbol = ctx.symbolProvider.toSymbol(collectionMemberTarget)
                                "${SwiftTypes.Int}(\$0).map({ intValue in $enumSymbol(rawValue: intValue) })"
                            } else {
                                "${stringToNumber(collectionMemberTarget, "\$0", false)}"
                            }
                        }
                        is TimestampShape -> {
                            val bindingIndex = HttpBindingIndex.of(ctx.model)
                            val tsFormat = bindingIndex.determineTimestampFormat(
                                hdrBinding.member,
                                HttpBinding.Location.HEADER,
                                defaultTimestampFormat
                            )
                            if (tsFormat == TimestampFormatTrait.Format.HTTP_DATE) {
                                splitFn = "splitHttpDateHeaderListValues"
                            }
                            invalidHeaderListErrorName = "invalidTimestampHeaderList"
                            "(${stringToDate("\$0", tsFormat)} ?? ${ClientRuntimeTypes.Core.Date}())"
                        }
                        is StringShape -> {
                            invalidHeaderListErrorName = "invalidStringHeaderList"
                            when {
                                collectionMemberTarget.hasTrait<EnumTrait>() -> {
                                    val enumSymbol = ctx.symbolProvider.toSymbol(collectionMemberTarget)
                                    "($enumSymbol(rawValue: \$0) ?? $enumSymbol(rawValue: \"Bar\")!)"
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
                        memberValue = "${SwiftTypes.Set}(${memberName}HeaderValues)"
                    }
                    writer.write("if let ${memberName}HeaderValues = try $splitFnPrefix$splitFn(${memberName}HeaderValue) {")
                    writer.indent()
                    // render map function
                    val collectionMemberTargetShape = ctx.model.expectShape(memberTarget.member.target)
                    val collectionMemberTargetSymbol = ctx.symbolProvider.toSymbol(collectionMemberTargetShape)
                    if (!collectionMemberTargetSymbol.isBoxed() || collectionMemberTargetShape.isIntEnumShape()) {
                        writer.openBlock("self.\$L = try \$LHeaderValues.map {", "}", memberName, memberName) {
                            val transformedHeaderDeclaration = "${memberName}Transformed"
                            writer.openBlock("guard let \$L = \$L else {", "}", transformedHeaderDeclaration, conversion) {
                                writer.write("throw HeaderDeserializationError.\$L(value: \$LHeaderValue)", invalidHeaderListErrorName, memberName)
                            }
                            writer.write("return \$L", transformedHeaderDeclaration)
                        }
                    } else {
                        writer.write("self.\$L\$L = \$L", path, memberName, memberValue)
                    }
                    writer.dedent()
                    writer.write("} else {")
                    writer.indent()
                    writer.write("self.$path\$L = nil", memberName)
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
            writer.write("self.$path$memberName = $assignmentValue")
            writer.dedent()
            writer.write("}")
        }
    }

    private fun stringToNumber(shape: NumberShape, stringValue: String, zeroDefaultValue: Boolean): String {
        val defaultValue = if (zeroDefaultValue) " ?? 0" else ""
        return when (shape.type) {
            ShapeType.BYTE -> "${SwiftTypes.Int8}($stringValue)$defaultValue"
            ShapeType.SHORT -> "${SwiftTypes.Int16}($stringValue)$defaultValue"
            ShapeType.INTEGER -> "${SwiftTypes.Int}($stringValue)$defaultValue"
            ShapeType.LONG -> "${SwiftTypes.Int}($stringValue)$defaultValue"
            ShapeType.FLOAT -> "${SwiftTypes.Float}($stringValue)$defaultValue"
            ShapeType.DOUBLE -> "${SwiftTypes.Double}($stringValue)$defaultValue"
            else -> throw CodegenException("unknown number shape: $shape")
        }
    }

    private fun stringToDate(stringValue: String, tsFormat: TimestampFormatTrait.Format): String {
        val timestampFormat = TimestampHelpers.generateTimestampFormatEnumValue(tsFormat)
        return "TimestampFormatter(format: .$timestampFormat).date(from: $stringValue)"
    }
}
