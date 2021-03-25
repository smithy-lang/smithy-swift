package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.model.traits.XmlFlattenedTrait
import software.amazon.smithy.swift.codegen.SwiftBoxTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeDecodeGeneratable
import software.amazon.smithy.swift.codegen.integration.serde.TimeStampFormat.Companion.determineTimestampFormat
import software.amazon.smithy.swift.codegen.isBoxed
import software.amazon.smithy.swift.codegen.recursiveSymbol

abstract class MemberShapeDecodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeDecodeGeneratable {

    fun renderListMember(
        member: MemberShape,
        memberTarget: CollectionShape,
        containerName: String
    ) {
        val memberName = ctx.symbolProvider.toMemberName(member).removeSurrounding("`", "`")
        val memberIsFlattened = member.hasTrait(XmlFlattenedTrait::class.java)
        var currContainerName = containerName
        var currContainerKey = ".$memberName"
        if (!memberIsFlattened) {
            val nextContainerName = "${memberName}WrappedContainer"
            writer.write("let $nextContainerName = try $currContainerName.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: $currContainerKey)")
            currContainerKey = ".member"
            currContainerName = nextContainerName
        }

        val memberBuffer = "${memberName}Buffer"
        val memberContainerName = "${memberName}Container"
        val (memberTargetSymbol, memberTargetSymbolName) = nestedMemberTargetSymbolMapper(memberTarget)
        writer.write("let $memberContainerName = try $currContainerName.decodeIfPresent($memberTargetSymbolName.self, forKey: $currContainerKey)")
        writer.write("var $memberBuffer:\$T = nil", memberTargetSymbol)
        writer.openBlock("if let $memberContainerName = $memberContainerName {", "}") {
            writer.write("$memberBuffer = $memberTargetSymbol()")

            val nestedMemberTarget = ctx.model.expectShape(memberTarget.member.target)
            val nestedMember = memberTarget.member
            renderListMemberItems(nestedMember, nestedMemberTarget, memberContainerName, memberBuffer)
        }
        writer.write("$memberName = $memberBuffer")
    }

    private fun renderListMemberItems(nestedMember: MemberShape, nestedMemberTarget: Shape, memberContainerName: String, memberBuffer: String, level: Int = 0) {
        val nestedMemberTargetSymbol = ctx.symbolProvider.toSymbol(nestedMemberTarget)
        val delimiter = if (level == 0) "?" else ""

        val nestedMemberTargetType = "${nestedMemberTarget.type.name.toLowerCase()}"
        val nestedContainerName = "${nestedMemberTargetType}Container$level"
        val nestedMemberBuffer = "${nestedMemberTargetType}Buffer$level"
        writer.openBlock("for $nestedContainerName in $memberContainerName {", "}") {
            when (nestedMemberTarget) {
                is CollectionShape -> {
                    writer.write("var $nestedMemberBuffer = $nestedMemberTargetSymbol()")
                    renderNestedListMemberTarget(nestedMemberTarget, nestedContainerName, nestedMemberBuffer, level + 1)
                    writer.write("$memberBuffer$delimiter.append($nestedMemberBuffer)")
                }
                is MapShape -> {
                    throw Exception("renderListMemberItems: maps not supported")
                }
                is TimestampShape -> {
                    val format = determineTimestampFormat(nestedMember, defaultTimestampFormat)
                    val wrappedNestedMemberBuffer = "TimestampWrapperDecoder.parseDateStringValue($nestedContainerName, format: .$format)"
                    writer.write("try $memberBuffer$delimiter.append($wrappedNestedMemberBuffer)")
                }
                else -> {
                    writer.write("$memberBuffer$delimiter.append($nestedContainerName)")
                }
            }
        }
    }

    private fun renderNestedListMemberTarget(memberTarget: CollectionShape, containerName: String, memberBuffer: String, level: Int) {
        val nestedMemberTarget = ctx.model.expectShape(memberTarget.member.target)
        val nestedMember = memberTarget.member
        val nestedMemberTargetIsBoxed = ctx.symbolProvider.toSymbol(nestedMemberTarget).isBoxed()
        if (nestedMemberTargetIsBoxed) {
            writer.openBlock("if let $containerName = $containerName {", "}") {
                renderListMemberItems(nestedMember, nestedMemberTarget, containerName, memberBuffer, level)
            }
        } else {
            renderListMemberItems(nestedMember, nestedMemberTarget, containerName, memberBuffer, level)
        }
    }

    fun renderMapMember(member: MemberShape, memberTarget: MapShape, containerName: String) {
        val memberTargetKey = ctx.symbolProvider.toSymbol(memberTarget.key)
        val memberTargetValue = ctx.symbolProvider.toSymbol(memberTarget.value)
        val symbolOptional = if (ctx.symbolProvider.toSymbol(memberTarget).isBoxed()) "?" else ""

        val memberName = ctx.symbolProvider.toMemberName(member)
        val memberNameUnquoted = memberName.removeSurrounding("`", "`")
        val translatedMemberTargetValueType = mapShapeIdToSymbolForMaps(memberTarget.value.target)
        var currContainerName = containerName
        var currContainerKey = ".$memberNameUnquoted"
        val memberIsFlattened = member.hasTrait(XmlFlattenedTrait::class.java)
        if (!memberIsFlattened) {
            val nextContainerName = "${memberNameUnquoted}WrappedContainer"
            writer.write("let $nextContainerName = try $currContainerName.nestedContainer(keyedBy: MapEntry<$memberTargetKey, $translatedMemberTargetValueType>.CodingKeys.self, forKey: $currContainerKey)")
            currContainerKey = ".entry"
            currContainerName = nextContainerName
        }

        val memberBuffer = "${memberNameUnquoted}Buffer"
        val memberContainerName = "${memberNameUnquoted}Container"
        val memberTargetSymbol = "[$memberTargetKey:$memberTargetValue]"
        writer.write("let $memberContainerName = try $currContainerName.decodeIfPresent([MapKeyValue<$memberTargetKey, $translatedMemberTargetValueType>].self, forKey: $currContainerKey)")

        writer.write("var $memberBuffer: ${memberTargetSymbol}$symbolOptional = nil",)
        writer.openBlock("if let $memberContainerName = $memberContainerName {", "}") {
            writer.write("$memberBuffer = $memberTargetSymbol()")
            val memberTargetValueTarget = ctx.model.expectShape(memberTarget.value.target)
            renderMapMemberItems(memberTargetValueTarget, memberContainerName, memberBuffer)
        }
        writer.write("$memberName = $memberBuffer")
    }

    private fun renderMapMemberItems(memberTarget: Shape, memberContainerName: String, memberBuffer: String, level: Int = 0) {
        val itemInContainerName = "${memberTarget.type.name.toLowerCase()}Container$level"

        val nestedBuffer = "nestedBuffer$level"
        val memberTargetSymbol = ctx.symbolProvider.toSymbol(memberTarget)
        if (memberTarget is CollectionShape || memberTarget is MapShape) {
            writer.write("var $nestedBuffer: $memberTargetSymbol? = nil")
        }

        writer.openBlock("for $itemInContainerName in $memberContainerName {", "}") {
            when (memberTarget) {
                is CollectionShape -> {
                    throw Exception("renderMapMemberItems: nested collections in maps not supported")
                }
                is MapShape -> {
                    renderMapEntry(memberTarget, itemInContainerName, nestedBuffer, level)
                    writer.write("$memberBuffer?[$itemInContainerName.key] = $nestedBuffer")
                }
                is TimestampShape -> {
                    throw Exception("renderMapMemberItems: nested timestamps not supported")
                }
                else -> {
                    writer.write("$memberBuffer?[$itemInContainerName.key] = $itemInContainerName.value")
                }
            }
        }
    }

    private fun renderMapEntry(memberTarget: MapShape, itemInContainerName: String, memberBuffer: String, level: Int) {
        val entryContainerName = "${itemInContainerName}NestedEntry$level"

        val memberTargetSymbol = ctx.symbolProvider.toSymbol(memberTarget)
        writer.write("$memberBuffer = $memberTargetSymbol()")
        writer.openBlock("if let $entryContainerName = $itemInContainerName.value.entry  {", "}") {
            val nestedMemberTarget = ctx.model.expectShape(memberTarget.value.target)
            renderMapMemberItems(nestedMemberTarget, entryContainerName, memberBuffer, level + 1)
        }
    }

    fun renderTimestampMember(member: MemberShape, memberTarget: TimestampShape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member).removeSurrounding("`", "`")
        var memberTargetSymbol = ctx.symbolProvider.toSymbol(memberTarget)
        val decodeVerb = if (memberTargetSymbol.isBoxed()) "decodeIfPresent" else "decode"
        val decodedMemberName = "${memberName}Decoded"
        writer.write("let $decodedMemberName = try $containerName.$decodeVerb(String.self, forKey: .$memberName)")

        val memberBuffer = "${memberName}Buffer"
        val format = determineTimestampFormat(member, defaultTimestampFormat)
        writer.write("var $memberBuffer:\$T = nil", memberTargetSymbol)
        writer.openBlock("if let $decodedMemberName = $decodedMemberName {", "}") {
            writer.write("$memberBuffer = try TimestampWrapperDecoder.parseDateStringValue($decodedMemberName, format: .$format)")
        }
        writer.write("$memberName = $memberBuffer")
    }

    fun renderScalarMember(member: MemberShape, memberTarget: Shape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member).removeSurrounding("`", "`")
        var memberTargetSymbol = ctx.symbolProvider.toSymbol(memberTarget)
        if (member.hasTrait(SwiftBoxTrait::class.java)) {
            memberTargetSymbol = memberTargetSymbol.recursiveSymbol()
        }
        val decodeVerb = if (memberTargetSymbol.isBoxed()) "decodeIfPresent" else "decode"
        val decodedMemberName = "${memberName}Decoded"
        writer.write("let $decodedMemberName = try $containerName.$decodeVerb(${memberTargetSymbol.name}.self, forKey: .$memberName)")
        writer.write("$memberName = $decodedMemberName")
    }

    private fun nestedMemberTargetSymbolMapper(collectionShape: CollectionShape): Pair<Symbol, String> {
        // TODO: double check this when we get around to supporting the following:
        //  * Sets
        //  * Unions
        val symbol = ctx.symbolProvider.toSymbol(collectionShape)
        if (symbol.name.contains("[Date]")) {
            val updatedName = symbol.name.replace("[Date]", "[String]")
            return Pair(symbol, updatedName)
        }
        return Pair(symbol, symbol.name)
    }

    private fun mapShapeIdToSymbolForMaps(targetShapeId: ShapeId): String {
        val targetShape = ctx.model.expectShape(targetShapeId)
        var mappedSymbol = when (targetShape) {
            is MapShape -> {
                val targetShapeKey = ctx.symbolProvider.toSymbol(targetShape.key)
                val valueEvaluated = mapShapeIdToSymbolForMaps(targetShape.value.target)
                "MapEntry<$targetShapeKey, $valueEvaluated>"
            }
            is CollectionShape -> {
                throw Exception("nested CollectionShape not yet supported")
            }
            else -> {
                "${ctx.symbolProvider.toSymbol(targetShape)}"
            }
        }
        return mappedSymbol
    }
}
