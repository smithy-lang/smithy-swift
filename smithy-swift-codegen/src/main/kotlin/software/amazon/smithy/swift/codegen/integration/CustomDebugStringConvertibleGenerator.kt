/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.ErrorTrait
import software.amazon.smithy.model.traits.SensitiveTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.toMemberNames
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes

class CustomDebugStringConvertibleGenerator(
    private val symbolProvider: SymbolProvider,
    private val writer: SwiftWriter,
    private val shape: StructureShape,
    private val model: Model,
) {
    companion object {
        const val REDACT_STRING = "CONTENT_REDACTED"

        fun Shape.isSensitive(model: Model): Boolean =
            when {
                this is MemberShape -> model.expectShape(target).isSensitive(model)
                hasTrait<SensitiveTrait>() -> true
                this is ListShape -> member.isSensitive(model)
                this is MapShape -> key.isSensitive(model) || value.isSensitive(model)
                else -> false
            }
    }

    private val structSymbol: Symbol by lazy {
        symbolProvider.toSymbol(shape)
    }

    private val membersSortedByName: List<MemberShape> = shape.allMembers.values.sortedBy { symbolProvider.toMemberName(it) }

    fun render() {
        writer.openBlock("extension \$N: \$N {", "}", structSymbol, SwiftTypes.Protocols.CustomDebugStringConvertible) {
            writer.openBlock("public var debugDescription: \$N {", "}", SwiftTypes.String) {
                if (shape.hasTrait<SensitiveTrait>()) {
                    writer.write("\"$REDACT_STRING\"")
                } else {
                    renderDescription()
                }
            }
        }
    }

    private fun renderDescription() {
        val symbolName = structSymbol.name
        writer.writeInline("\"$symbolName(")
        val (membersWithSensitiveTrait, membersWithoutSensitiveTrait) = membersSortedByName.partition { it.isSensitive(model) }
        for (member in membersWithoutSensitiveTrait) {
            renderMemberDescription(writer, member, false)
            renderComma(writer, member != membersWithoutSensitiveTrait.last())
        }
        if (membersWithSensitiveTrait.isNotEmpty()) {
            renderComma(writer, membersWithoutSensitiveTrait.isNotEmpty())
            for (member in membersWithSensitiveTrait) {
                renderMemberDescription(writer, member, true)
                renderComma(writer, member != membersWithSensitiveTrait.last())
            }
        }
        writer.writeInline(")\"")
    }

    private fun renderMemberDescription(
        writer: SwiftWriter,
        member: MemberShape,
        isRedacted: Boolean,
    ) {
        val memberNames = symbolProvider.toMemberNames(member)
        val path = "properties.".takeIf { shape.hasTrait<ErrorTrait>() } ?: ""
        var description = ""
        if (model.expectShape(member.target).isMapShape) {
            description = getStringForLoggingMapShape(model.expectShape(member.target).asMapShape().get(), path, memberNames)
        } else {
            description = if (isRedacted) "\\\"$REDACT_STRING\\\"" else "\\(${SwiftTypes.String}(describing: $path${memberNames.first}))"
        }
        writer.writeInline("${memberNames.second}: $description")
    }

    private fun renderComma(
        writer: SwiftWriter,
        shouldWriteComma: Boolean,
    ) {
        if (shouldWriteComma) {
            writer.writeInline(", ")
        }
    }

    private fun getStringForLoggingMapShape(
        member: MapShape,
        path: String,
        memberNames: Pair<String, String>,
    ): String {
        if (member.hasTrait<SensitiveTrait>()) return "\\\"$REDACT_STRING\\\""
        if (member.key.isSensitive(model) && member.value.isSensitive(model)) return "\\\"$REDACT_STRING\\\""
        if (member.key.isSensitive(
                model,
            )
        ) {
            return "[keys: \\\"$REDACT_STRING\\\", values: \\(${SwiftTypes.String}(describing: $path${memberNames.first}?.values))]"
        }
        if (member.value.isSensitive(
                model,
            )
        ) {
            return "[keys: \\(${SwiftTypes.String}(describing: $path${memberNames.first}?.keys)), values: \\\"$REDACT_STRING\\\"]"
        }
        return "\\(${SwiftTypes.String}(describing: $path${memberNames.first}))"
    }
}
