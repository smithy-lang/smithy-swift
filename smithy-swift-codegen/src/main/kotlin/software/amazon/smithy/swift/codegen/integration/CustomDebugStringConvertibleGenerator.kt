package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.SensitiveTrait
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.toMemberNames

class CustomDebugStringConvertibleGenerator(
    private val symbolProvider: SymbolProvider,
    private val writer: SwiftWriter,
    private val shape: StructureShape
) {
    companion object {
        const val REDACT_STRING = "CONTENT_REDACTED"
    }

    private val structSymbol: Symbol by lazy {
        symbolProvider.toSymbol(shape)
    }

    private val membersSortedByName: List<MemberShape> = shape.allMembers.values.sortedBy { symbolProvider.toMemberName(it) }

    fun render() {
        writer.openBlock("extension ${structSymbol.name}: \$T {", "}", SwiftTypes.Protocols.CustomDebugStringConvertible) {
            writer.openBlock("public var debugDescription: \$T {", "}", SwiftTypes.String) {
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
        val membersWithoutSensitiveTrait = membersSortedByName
            .filterNot { it.hasTrait(SensitiveTrait::class.java) }
            .sortedBy { it.memberName }
            .toList()
        val membersWithSensitiveTrait = membersSortedByName
            .filter { it.hasTrait(SensitiveTrait::class.java) }
            .sortedBy { it.memberName }
            .toList()
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
        isRedacted: Boolean
    ) {
        val memberNames = symbolProvider.toMemberNames(member)
        val description = if (isRedacted) "\\\"$REDACT_STRING\\\"" else "\\(${SwiftTypes.String.fullName}(describing: ${memberNames.first}))"
        writer.writeInline("${memberNames.second}: $description")
    }

    private fun renderComma(writer: SwiftWriter, shouldWriteComma: Boolean) {
        if (shouldWriteComma) {
            writer.writeInline(", ")
        }
    }
}
