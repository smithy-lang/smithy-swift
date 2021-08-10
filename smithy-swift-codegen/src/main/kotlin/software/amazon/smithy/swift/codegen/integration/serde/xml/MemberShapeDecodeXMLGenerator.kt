package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.BlobShape
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.SetShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.SparseTrait
import software.amazon.smithy.model.traits.StreamingTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.model.traits.XmlFlattenedTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.customtraits.SwiftBoxTrait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeDecodeGeneratable
import software.amazon.smithy.swift.codegen.integration.serde.TimeStampFormat.Companion.determineTimestampFormat
import software.amazon.smithy.swift.codegen.integration.serde.xml.collection.CollectionMemberCodingKey
import software.amazon.smithy.swift.codegen.integration.serde.xml.collection.MapKeyValue
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.model.isBoxed
import software.amazon.smithy.swift.codegen.model.recursiveSymbol

abstract class MemberShapeDecodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeDecodeGeneratable {
    abstract fun renderAssigningDecodedMember(memberName: String, decodedMemberName: String, isBoxed: Boolean = false)
    abstract fun renderAssigningSymbol(memberName: String, symbol: String)
    abstract fun renderAssigningNil(memberName: String)

    fun renderListMember(
        member: MemberShape,
        memberTarget: CollectionShape,
        containerName: String
    ) {
        val memberName = ctx.symbolProvider.toMemberName(member).removeSurrounding("`", "`")
        val memberIsFlattened = member.hasTrait(XmlFlattenedTrait::class.java)
        var currContainerName = containerName
        var currContainerKey = ".$memberName"

        writer.openBlock("if $containerName.contains(.$memberName) {", "} else {") {
            var containerUsedForDecoding: String
            var ifNilOrIfLetStatement: String
            val nextContainerName = "${memberName}WrappedContainer"
            if (!memberIsFlattened) {
                val memberCodingKey = CollectionMemberCodingKey.construct(memberTarget.member)
                memberCodingKey.renderStructs(writer)
                writer.write("let $nextContainerName = $currContainerName.nestedContainerNonThrowable(keyedBy: CollectionMemberCodingKey<${memberCodingKey.keyTag()}>.CodingKeys.self, forKey: $currContainerKey)")
                currContainerKey = ".member"
                currContainerName = nextContainerName
                containerUsedForDecoding = currContainerName
                ifNilOrIfLetStatement = "if let $currContainerName = $currContainerName {"
            } else {
                writer.write("let $nextContainerName = $currContainerName.nestedContainerNonThrowable(keyedBy: CodingKeys.self, forKey: $currContainerKey)")
                // currContainerKey is intentionally not updated. This container is only used to detect empty lists, not for decoding.
                currContainerName = nextContainerName
                containerUsedForDecoding = containerName
                ifNilOrIfLetStatement = "if $currContainerName != nil {"
            }

            writer.openBlock(ifNilOrIfLetStatement, "} else {") {
                val memberBuffer = "${memberName}Buffer"
                val memberContainerName = "${memberName}Container"
                val (memberTargetSymbol, memberTargetSymbolName) = nestedMemberTargetSymbolMapper(memberTarget)
                writer.write("let $memberContainerName = try $containerUsedForDecoding.decodeIfPresent($memberTargetSymbolName.self, forKey: $currContainerKey)")
                writer.write("var $memberBuffer:\$T = nil", memberTargetSymbol)
                writer.openBlock("if let $memberContainerName = $memberContainerName {", "}") {
                    writer.write("$memberBuffer = \$N()", memberTargetSymbol)
                    renderListMemberItems(memberTarget, memberContainerName, memberBuffer)
                }
                renderAssigningDecodedMember(memberName, memberBuffer)
            }
            writer.indent()
            renderAssigningSymbol(memberName, "[]")
            writer.dedent().write("}")
        }
        writer.indent()
        renderAssigningNil(memberName)
        writer.dedent().write("}")
    }

    private fun renderListMemberItems(memberTarget: CollectionShape, memberContainerName: String, memberBuffer: String, level: Int = 0) {
        val nestedMemberTarget = ctx.model.expectShape(memberTarget.member.target)
        val nestedMember = memberTarget.member
        val nestedMemberTargetSymbol = ctx.symbolProvider.toSymbol(nestedMemberTarget)

        val nestedMemberTargetType = "${nestedMemberTarget.type.name.toLowerCase()}"
        val nestedContainerName = "${nestedMemberTargetType}Container$level"
        val nestedMemberBuffer = "${nestedMemberTargetType}Buffer$level"
        val insertMethod = when (memberTarget) {
            is SetShape -> "insert"
            is ListShape -> "append"
            else -> "append"
        }
        if (nestedMemberTarget is CollectionShape || nestedMemberTarget is MapShape) {
            writer.write("var $nestedMemberBuffer: \$T = nil", nestedMemberTargetSymbol)
        }

        writer.openBlock("for $nestedContainerName in $memberContainerName {", "}") {
            when (nestedMemberTarget) {
                is ListShape -> {
                    renderNestedListMemberTarget(nestedMemberTarget, nestedContainerName, nestedMemberBuffer, level + 1)
                    writer.openBlock("if let $nestedMemberBuffer = $nestedMemberBuffer {", "}") {
                        writer.write("$memberBuffer?.$insertMethod($nestedMemberBuffer)")
                    }
                }
                is MapShape -> {
                    renderMapEntry(nestedMemberTarget, nestedContainerName, "entry", nestedMemberBuffer, level + 1)
                    writer.openBlock("if let $nestedMemberBuffer = $nestedMemberBuffer {", "}") {
                        writer.write("$memberBuffer?.$insertMethod($nestedMemberBuffer)")
                    }
                }
                is SetShape -> {
                    renderNestedListMemberTarget(nestedMemberTarget, nestedContainerName, nestedMemberBuffer, level + 1)
                    writer.openBlock("if let $nestedMemberBuffer = $nestedMemberBuffer {", "}") {
                        writer.write("$memberBuffer?.$insertMethod($nestedMemberBuffer)")
                    }
                }
                is TimestampShape -> {
                    val format = determineTimestampFormat(nestedMember, nestedMemberTarget, defaultTimestampFormat)
                    val wrappedNestedMemberBuffer = "${ClientRuntimeTypes.Serde.TimestampWrapperDecoder}.parseDateStringValue($nestedContainerName, format: .$format)"
                    writer.write("try $memberBuffer?.$insertMethod($wrappedNestedMemberBuffer)")
                }
                else -> {
                    writer.write("$memberBuffer?.$insertMethod($nestedContainerName)")
                }
            }
        }
    }

    private fun renderNestedListMemberTarget(memberTarget: CollectionShape, containerName: String, memberBuffer: String, level: Int) {
        val nestedMemberTarget = ctx.model.expectShape(memberTarget.member.target)
        val nestedMemberTargetIsBoxed = ctx.symbolProvider.toSymbol(nestedMemberTarget).isBoxed() && memberTarget.hasTrait<SparseTrait>()

        val isSetShape = memberTarget is SetShape

        val memberTargetSymbol = ctx.symbolProvider.toSymbol(memberTarget)
        writer.write("$memberBuffer = \$N()", memberTargetSymbol)
        if (nestedMemberTargetIsBoxed && !isSetShape) {
            writer.openBlock("if let $containerName = $containerName {", "}") {
                renderListMemberItems(memberTarget, containerName, memberBuffer, level)
            }
        } else {
            renderListMemberItems(memberTarget, containerName, memberBuffer, level)
        }
    }

    fun renderMapMember(member: MemberShape, memberTarget: MapShape, containerName: String) {
        val memberTargetValue = ctx.symbolProvider.toSymbol(memberTarget.value)
        val symbolOptional = if (ctx.symbolProvider.toSymbol(memberTarget).isBoxed()) "?" else ""

        val memberName = ctx.symbolProvider.toMemberName(member)
        val memberNameUnquoted = memberName.removeSurrounding("`", "`")
        var currContainerName = containerName
        var currContainerKey = ".$memberNameUnquoted"
        val memberIsFlattened = member.hasTrait<XmlFlattenedTrait>()
        writer.openBlock("if $containerName.contains(.$memberName) {", "} else {") {
            val keyedBySymbolForContainer = determineSymbolForShapeInMap(memberTarget, ClientRuntimeTypes.Serde.MapEntry, true)
            var containerUsedForDecoding: String
            var ifNilOrIfLetStatement: String
            val nextContainerName = "${memberNameUnquoted}WrappedContainer"
            writer.write("let $nextContainerName = $currContainerName.nestedContainerNonThrowable(keyedBy: $keyedBySymbolForContainer.CodingKeys.self, forKey: $currContainerKey)")
            if (!memberIsFlattened) {
                currContainerKey = ".entry"
                currContainerName = nextContainerName
                containerUsedForDecoding = currContainerName
                ifNilOrIfLetStatement = "if let $currContainerName = $currContainerName {"
            } else {
                // currContainerKey is intentionally not updated. This container is only used to detect empty lists, not for decoding.
                currContainerName = nextContainerName
                containerUsedForDecoding = containerName
                ifNilOrIfLetStatement = "if $currContainerName != nil {"
            }

            writer.openBlock(ifNilOrIfLetStatement, "} else {") {
                val memberBuffer = "${memberNameUnquoted}Buffer"
                val memberContainerName = "${memberNameUnquoted}Container"
                val memberTargetSymbol = "[${SwiftTypes.String}:${memberTargetValue}]"

                val symbolToDecodeTo = determineSymbolForShapeInMap(memberTarget, ClientRuntimeTypes.Serde.MapKeyValue, false)
                writer.write("let $memberContainerName = try $containerUsedForDecoding.decodeIfPresent([$symbolToDecodeTo].self, forKey: $currContainerKey)")
                writer.write("var $memberBuffer: ${memberTargetSymbol}$symbolOptional = nil")
                writer.openBlock("if let $memberContainerName = $memberContainerName {", "}") {
                    writer.write("$memberBuffer = $memberTargetSymbol()")
                    renderMapMemberItems(memberTarget.value, memberContainerName, memberBuffer)
                }
                renderAssigningDecodedMember(memberName, memberBuffer)
            }
            writer.indent()
            renderAssigningSymbol(memberName, "[:]")
            writer.dedent().write("}")
        }
        writer.indent()
        renderAssigningNil(memberName)
        writer.dedent().write("}")
    }

    private fun renderMapMemberItems(memberShape: MemberShape, memberContainerName: String, memberBuffer: String, level: Int = 0) {
        val memberTarget = ctx.model.expectShape(memberShape.target)
        val itemInContainerName = "${memberTarget.type.name.toLowerCase()}Container$level"

        val nestedBuffer = "nestedBuffer$level"
        val memberTargetSymbol = ctx.symbolProvider.toSymbol(memberTarget)
        if (memberTarget is CollectionShape || memberTarget is MapShape) {
            writer.write("var $nestedBuffer: \$T = nil", memberTargetSymbol)
        }

        writer.openBlock("for $itemInContainerName in $memberContainerName {", "}") {
            when (memberTarget) {
                is CollectionShape -> {
                    writer.write("$nestedBuffer = \$N()", memberTargetSymbol)
                    renderListMemberItems(memberTarget, "$itemInContainerName.value.member", nestedBuffer, level)
                    writer.write("$memberBuffer?[$itemInContainerName.key] = $nestedBuffer")
                }
                is MapShape -> {
                    renderMapEntry(memberTarget, itemInContainerName, "value.entry", nestedBuffer, level)
                    writer.write("$memberBuffer?[$itemInContainerName.key] = $nestedBuffer")
                }
                is TimestampShape -> {
                    val format = determineTimestampFormat(memberShape, memberTarget, defaultTimestampFormat)
                    writer.write("$memberBuffer?[$itemInContainerName.key] = try \$N.parseDateStringValue($itemInContainerName.value, format: .$format)", ClientRuntimeTypes.Serde.TimestampWrapperDecoder)
                }
                else -> {
                    writer.write("$memberBuffer?[$itemInContainerName.key] = $itemInContainerName.value")
                }
            }
        }
    }

    private fun renderMapEntry(memberTarget: MapShape, itemInContainerName: String, entryLocation: String, memberBuffer: String, level: Int) {
        val entryContainerName = "${itemInContainerName}NestedEntry$level"

        val memberTargetSymbol = ctx.symbolProvider.toSymbol(memberTarget)
        writer.write("$memberBuffer = \$N()", memberTargetSymbol)
        writer.openBlock("if let $entryContainerName = $itemInContainerName.$entryLocation {", "}") {
            renderMapMemberItems(memberTarget.value, entryContainerName, memberBuffer, level + 1)
        }
    }

    fun renderTimestampMember(member: MemberShape, memberTarget: TimestampShape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member).removeSurrounding("`", "`")
        var memberTargetSymbol = ctx.symbolProvider.toSymbol(memberTarget)
        val decodeVerb = if (memberTargetSymbol.isBoxed()) "decodeIfPresent" else "decode"
        val decodedMemberName = "${memberName}Decoded"
        writer.write("let $decodedMemberName = try $containerName.$decodeVerb(\$N.self, forKey: .$memberName)", SwiftTypes.String)

        val memberBuffer = "${memberName}Buffer"
        val format = determineTimestampFormat(member, memberTarget, defaultTimestampFormat)
        writer.write("var $memberBuffer:\$T = nil", memberTargetSymbol)
        writer.openBlock("if let $decodedMemberName = $decodedMemberName {", "}") {
            writer.write("$memberBuffer = try \$N.parseDateStringValue($decodedMemberName, format: .$format)", ClientRuntimeTypes.Serde.TimestampWrapperDecoder)
        }
        renderAssigningDecodedMember(memberName, memberBuffer)
    }

    fun renderBlobMember(member: MemberShape, memberTarget: BlobShape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val memberNameUnquoted = memberName.removeSurrounding("`", "`")
        var memberTargetSymbol = ctx.symbolProvider.toSymbol(memberTarget)
        if (member.hasTrait(SwiftBoxTrait::class.java)) {
            memberTargetSymbol = memberTargetSymbol.recursiveSymbol()
        }
        val decodedMemberName = "${memberName}Decoded"
        writer.openBlock("if $containerName.contains(.$memberNameUnquoted) {", "} else {") {
            writer.openBlock("do {", "} catch {") {
                writer.write("let $decodedMemberName = try $containerName.decodeIfPresent(\$N.self, forKey: .$memberNameUnquoted)", memberTargetSymbol)
                renderAssigningDecodedMember(memberName, decodedMemberName)
            }
            writer.indent()
            renderEmptyDataForBlobTarget(memberTarget, memberName)
            writer.dedent().write("}")
        }
        writer.indent()
        renderAssigningNil(memberName)
        writer.dedent().write("}")
    }

    private fun renderEmptyDataForBlobTarget(memberTarget: Shape, memberName: String) {
        val isStreaming = memberTarget.hasTrait<StreamingTrait>()
        val value = if (isStreaming) "${ClientRuntimeTypes.Core.ByteStream}.from(data: \"\".data(using: .utf8)!)" else "\"\".data(using: .utf8)"
        renderAssigningDecodedMember(memberName, "$value")
    }

    fun renderScalarMember(member: MemberShape, memberTarget: Shape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val memberNameUnquoted = memberName.removeSurrounding("`", "`")
        var memberTargetSymbol = ctx.symbolProvider.toSymbol(memberTarget)
        if (member.hasTrait(SwiftBoxTrait::class.java)) {
            memberTargetSymbol = memberTargetSymbol.recursiveSymbol()
        }
        val decodeVerb = if (memberTargetSymbol.isBoxed()) "decodeIfPresent" else "decode"
        val decodedMemberName = "${memberNameUnquoted}Decoded"
        writer.write("let $decodedMemberName = try $containerName.$decodeVerb(\$N.self, forKey: .$memberNameUnquoted)", memberTargetSymbol)
        renderAssigningDecodedMember(memberName, decodedMemberName, member.hasTrait(SwiftBoxTrait::class.java))
    }

    private fun nestedMemberTargetSymbolMapper(collectionShape: CollectionShape): Pair<Symbol, String> {
        val symbol = ctx.symbolProvider.toSymbol(collectionShape)
        if (symbol.name.contains("[${ClientRuntimeTypes.Core.Date}]")) {
            val updatedName = symbol.name.replace("[${ClientRuntimeTypes.Core.Date}]", "[${SwiftTypes.String}]")
            return Pair(symbol, updatedName)
        }
        val nestedMemberTarget = ctx.model.expectShape(collectionShape.member.target)
        val symbolName = "[${convertListSymbolName(nestedMemberTarget)}]"
        return Pair(symbol, symbolName)
    }

    private fun convertListSymbolName(shape: Shape): String {
        val mappedSymbol = when (shape) {
            is ListShape -> {
                val nestedShape = ctx.model.expectShape(shape.member.target)
                "[${convertListSymbolName(nestedShape)}]"
            }
            is SetShape -> {
                val nestedShape = ctx.model.expectShape(shape.member.target)
                "[${convertListSymbolName(nestedShape)}]"
            }
            is MapShape -> {
                return determineSymbolForShapeInMap(shape, ClientRuntimeTypes.Serde.MapEntry, true)
            }
            else -> {
                ctx.symbolProvider.toSymbol(shape).toString()
            }
        }
        return mappedSymbol
    }

    private fun determineSymbolForShapeInMap(currShape: Shape, containingSymbol: Symbol, shouldRenderStructs: Boolean, level: Int = 0): String {
        var mappedSymbol = when (currShape) {
            is MapShape -> {
                val keyValueName = MapKeyValue.constructMapKeyValue(currShape.key, currShape.value, level)
                if (shouldRenderStructs) {
                    keyValueName.renderStructs(writer)
                }
                val targetShape = ctx.model.expectShape(currShape.value.target)
                val valueEvaluated = determineSymbolForShapeInMap(targetShape, ClientRuntimeTypes.Serde.MapEntry, shouldRenderStructs, level + 1)
                "${containingSymbol}<${SwiftTypes.String}, $valueEvaluated, ${keyValueName.keyTag()}, ${keyValueName.valueTag()}>"
            }
            is CollectionShape -> {
                val collectionName = CollectionMemberCodingKey.construct(currShape.member, level)
                if (shouldRenderStructs) {
                    collectionName.renderStructs(writer)
                }
                val targetShape = ctx.model.expectShape(currShape.member.target)
                val nestedShape = determineSymbolForShapeInMap(targetShape, ClientRuntimeTypes.Serde.MapEntry, shouldRenderStructs, level + 1)
                "${ClientRuntimeTypes.Serde.CollectionMember}<$nestedShape, ${collectionName.keyTag()}>"
            }
            is TimestampShape -> {
                SwiftTypes.String.toString()
            }
            else -> {
                ctx.symbolProvider.toSymbol(currShape).toString()
            }
        }
        return mappedSymbol
    }
}
