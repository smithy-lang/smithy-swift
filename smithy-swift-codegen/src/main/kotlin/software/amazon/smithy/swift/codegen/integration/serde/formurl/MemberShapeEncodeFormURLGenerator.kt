package software.amazon.smithy.swift.codegen.integration.serde.formurl

import software.amazon.smithy.model.shapes.BlobShape
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.SetShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.model.traits.XmlFlattenedTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeEncodeConstants
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeEncodeGeneratable
import software.amazon.smithy.swift.codegen.integration.serde.TimeStampFormat
import software.amazon.smithy.swift.codegen.integration.serde.getDefaultValueOfShapeType
import software.amazon.smithy.swift.codegen.integration.serde.xml.trait.XMLNameTraitGenerator
import software.amazon.smithy.swift.codegen.isBoxed

abstract class MemberShapeEncodeFormURLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val customizations: FormURLEncodeCustomizable,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeEncodeGeneratable {

    fun renderListMember(
        member: MemberShape,
        memberTarget: CollectionShape,
        containerName: String
    ) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val resolvedMemberName = XMLNameTraitGenerator.construct(member, member.memberName)
        val nestedContainer = "${memberName}Container"
        writer.openBlock("if let $memberName = $memberName {", "}") {
            if (member.hasTrait(XmlFlattenedTrait::class.java) || customizations.alwaysUsesFlattenedCollections()) {
                writer.openBlock("if $memberName.isEmpty {", "} else {") {
                    writer.write("var $nestedContainer = $containerName.nestedUnkeyedContainer(forKey: Key(\"$resolvedMemberName\"))")
                    writer.write("try $nestedContainer.encodeNil()")
                }
                writer.indent()
                renderFlattenedListMemberItems(memberName, member, memberTarget, containerName)
                writer.dedent()
                writer.write("}")
            } else {
                writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"$resolvedMemberName\"))")
                renderListMemberItems(memberName, memberTarget, nestedContainer)
            }
        }
    }

    private fun renderListMemberItems(
        memberName: String,
        memberTarget: CollectionShape,
        containerName: String,
        level: Int = 0
    ) {
        val nestedMember = memberTarget.member
        val nestedMemberResolvedName = XMLNameTraitGenerator.construct(nestedMember, "member").toString().indexAdvancedBy1("index$level")

        val nestedMemberTarget = ctx.model.expectShape(memberTarget.member.target)
        val nestedMemberTargetName = "${nestedMemberTarget.id.name.toLowerCase()}$level"
        writer.openBlock("for (index$level, $nestedMemberTargetName) in $memberName.enumerated() {", "}") {
            when (nestedMemberTarget) {
                is CollectionShape -> {
                    val isBoxed = ctx.symbolProvider.toSymbol(nestedMemberTarget).isBoxed()
                    if (isBoxed && !(nestedMemberTarget is SetShape)) {
                        writer.openBlock("if let $nestedMemberTargetName = $nestedMemberTargetName {", "}") {
                            renderNestedListEntryMember(nestedMemberTargetName, nestedMemberTarget, nestedMember, nestedMemberResolvedName, containerName, level)
                        }
                    } else {
                        renderNestedListEntryMember(nestedMemberTargetName, nestedMemberTarget, nestedMember, nestedMemberResolvedName, containerName, level)
                    }
                }
                is MapShape -> {
                    val nestedContainerName = "${memberName}Container$level"
                    writer.write("var $nestedContainerName = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"${nestedMemberResolvedName}\"))")
                    writer.openBlock("if let $nestedMemberTargetName = $nestedMemberTargetName {", "}") {
                        renderWrappedMapMemberItem(nestedMemberTargetName, nestedMemberTarget, nestedContainerName, level)
                    }
                }
                is TimestampShape -> {
                    val format = TimeStampFormat.determineTimestampFormat(nestedMember, nestedMemberTarget, defaultTimestampFormat)
                    val encodeValue = "TimestampWrapper($nestedMemberTargetName, format: .$format), forKey: Key(\"${nestedMemberResolvedName}\")"
                    writer.write("try $containerName.encode($encodeValue)")
                }
                is BlobShape -> {
                    renderBlobMemberName(nestedMemberTargetName, nestedMemberResolvedName, containerName, false)
                }
                else -> {
                    renderItem(writer, containerName, nestedMemberTargetName, nestedMemberResolvedName)
                }
            }
        }
    }

    private fun renderNestedListEntryMember(nestedMemberTargetName: String, nestedMemberTarget: CollectionShape, nestedMember: MemberShape, nestedMemberResolvedName: String, containerName: String, level: Int) {
        var nestedContainerName = "${nestedMemberTargetName}Container$level"
        writer.write("var $nestedContainerName = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"${nestedMemberResolvedName}\"))")
        renderListMemberItems(nestedMemberTargetName, nestedMemberTarget, nestedContainerName, level + 1)
    }

    private fun renderFlattenedListMemberItems(
        memberName: String,
        member: MemberShape,
        memberTarget: CollectionShape,
        containerName: String,
        level: Int = 0
    ) {
        val nestedMember = memberTarget.member
        val nestedMemberTarget = ctx.model.expectShape(memberTarget.member.target)
        val nestedMemberTargetName = "${nestedMemberTarget.id.name.toLowerCase()}$level"
        val defaultMemberName = if (level == 0) member.memberName else "member"
        val resolvedMemberName = XMLNameTraitGenerator.construct(member, defaultMemberName).toString().indexAdvancedBy1("index$level")
        val nestedContainerName = "${memberName}Container$level"

        writer.openBlock("for (index$level, $nestedMemberTargetName) in $memberName.enumerated() {", "}") {
            when (nestedMemberTarget) {
                is CollectionShape -> {
                    val isBoxed = ctx.symbolProvider.toSymbol(nestedMemberTarget).isBoxed()
                    if (isBoxed && !(nestedMemberTarget is SetShape)) {
                        writer.openBlock("if let $nestedMemberTargetName = $nestedMemberTargetName {", "}") {
                            renderFlattenedListContainer(nestedMemberTargetName, nestedMemberTarget, nestedMember, memberName, member, containerName, level)
                        }
                    } else {
                        renderFlattenedListContainer(nestedMemberTargetName, nestedMemberTarget, nestedMember, memberName, member, containerName, level)
                    }
                }
                is MapShape -> {
                    writer.write("var $nestedContainerName = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedMemberName}\"))")
                    writer.openBlock("if let $nestedMemberTargetName = $nestedMemberTargetName {", "}") {
                        renderWrappedMapMemberItem(nestedMemberTargetName, nestedMemberTarget, nestedContainerName, level)
                    }
                }
                is TimestampShape -> {
                    writer.write("var $nestedContainerName = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"$resolvedMemberName\"))")
                    val format = TimeStampFormat.determineTimestampFormat(nestedMember, nestedMemberTarget, defaultTimestampFormat)
                    val encodeValue = "TimestampWrapper($nestedMemberTargetName, format: .$format), forKey: Key(\"\")"
                    writer.write("try $nestedContainerName.encode($encodeValue)")
                }
                is BlobShape -> {
                    renderBlobMemberName(nestedMemberTargetName, resolvedMemberName, containerName, false)
                }
                else -> {
                    writer.write("var $nestedContainerName = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"$resolvedMemberName\"))")
                    writer.write("try $nestedContainerName.encode($nestedMemberTargetName, forKey: Key(\"\"))")
                }
            }
        }
    }
    private fun renderFlattenedListContainer(nestedMemberTargetName: String, nestedMemberTarget: CollectionShape, nestedMember: MemberShape, memberName: String, member: MemberShape, containerName: String, level: Int) {
        var nestedContainerName = "${nestedMemberTargetName}Container$level"
        val defaultMemberName = if (level == 0) memberName else "member"
        val memberResolvedName = XMLNameTraitGenerator.construct(member, defaultMemberName)
        writer.write("var $nestedContainerName = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"${memberResolvedName}\"))")
        renderFlattenedListMemberItems(nestedMemberTargetName, nestedMember, nestedMemberTarget, nestedContainerName, level + 1)
    }

    fun renderMapMember(member: MemberShape, memberTarget: MapShape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val resolvedMemberName = XMLNameTraitGenerator.construct(member, member.memberName)

        writer.openBlock("if let $memberName = $memberName {", "}") {
            if (member.hasTrait(XmlFlattenedTrait::class.java) || customizations.alwaysUsesFlattenedCollections()) {
                writer.openBlock("if $memberName.isEmpty {", "} else {") {
                    writer.write("let _ =  $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"$resolvedMemberName\"))")
                }
                writer.indent()
                renderFlattenedMapMemberItem(memberName, member, memberTarget, containerName)
                writer.dedent().write("}")
            } else {
                val nestedContainer = "${memberName}Container"
                writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"$resolvedMemberName\"))")
                renderWrappedMapMemberItem(memberName, memberTarget, nestedContainer)
            }
        }
    }

    private fun renderWrappedMapMemberItem(memberName: String, mapShape: MapShape, containerName: String, level: Int = 0) {
        val keyTargetShape = ctx.model.expectShape(mapShape.key.target)
        val valueTargetShape = ctx.model.expectShape(mapShape.value.target)

        val resolvedCodingKeys = Pair(
            XMLNameTraitGenerator.construct(mapShape.key, "key"),
            XMLNameTraitGenerator.construct(mapShape.value, "value")
        )

        val nestedKeyValueName = Pair("${keyTargetShape.id.name.toLowerCase()}Key$level", "${valueTargetShape.id.name.toLowerCase()}Value$level")
        val entryContainerName = "entryContainer$level"
        val index = "index$level"
        val element = "element$level"
        // Sorting the unordered map is needed for passing protocol codegen tests
        writer.openBlock("for ($index, $element) in $memberName.sorted(by: { $$0.key < $$1.key }).enumerated() {", "}") {
            writer.write("let ${nestedKeyValueName.first} = $element.key")
            writer.write("let ${nestedKeyValueName.second} = $element.value")

            val entry = "entry".indexAdvancedBy1(index)
            writer.write("var $entryContainerName = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"$entry\"))")
            renderMapKey(nestedKeyValueName, resolvedCodingKeys, mapShape, entryContainerName, level)
            when (valueTargetShape) {
                is MapShape -> {
                    renderMapNestedValue(nestedKeyValueName, resolvedCodingKeys, mapShape, valueTargetShape, entryContainerName, level) { valueContainer ->
                        renderWrappedMapMemberItem(nestedKeyValueName.second, valueTargetShape, valueContainer, level + 1)
                    }
                }
                is CollectionShape -> {
                    renderMapNestedValue(nestedKeyValueName, resolvedCodingKeys, mapShape, valueTargetShape, entryContainerName, level) { valueContainer ->
                        renderListMemberItems(nestedKeyValueName.second, valueTargetShape, valueContainer, level + 1)
                    }
                }
                is TimestampShape -> {
                    renderMapValue(nestedKeyValueName, resolvedCodingKeys, mapShape, entryContainerName, level) { valueContainer ->
                        val format = TimeStampFormat.determineTimestampFormat(mapShape.value, valueTargetShape, defaultTimestampFormat)
                        writer.write("try $valueContainer.encode(TimestampWrapper(${nestedKeyValueName.second}, format: .$format), forKey: Key(\"\"))")
                    }
                }
                is BlobShape -> {
                    renderMapValue(nestedKeyValueName, resolvedCodingKeys, mapShape, entryContainerName, level) { valueContainer ->
                        renderBlobMemberName(nestedKeyValueName.second, "", valueContainer, false)
                    }
                }
                else -> {
                    renderMapValue(nestedKeyValueName, resolvedCodingKeys, mapShape, entryContainerName, level)
                }
            }
        }
    }

    private fun renderFlattenedMapMemberItem(memberName: String, member: MemberShape, mapShape: MapShape, containerName: String, level: Int = 0) {
        val keyTargetShape = ctx.model.expectShape(mapShape.key.target)
        val valueTargetShape = ctx.model.expectShape(mapShape.value.target)

        val resolvedMemberName = if (level == 0) XMLNameTraitGenerator.construct(member, member.memberName) else "entry"

        val resolvedCodingKeys = Pair(
            XMLNameTraitGenerator.construct(mapShape.key, "key"),
            XMLNameTraitGenerator.construct(mapShape.value, "value")
        )

        val nestedKeyValueName = Pair("${keyTargetShape.id.name.toLowerCase()}Key$level", "${valueTargetShape.id.name.toLowerCase()}Value$level")
        val nestedContainer = "nestedContainer$level"
        val index = "index$level"
        val element = "element$level"
        // Sorting the unordered map is needed for passing protocol codegen tests
        writer.openBlock("for ($index, $element) in $memberName.sorted(by: { $$0.key < $$1.key }).enumerated() {", "}") {
            writer.write("let ${nestedKeyValueName.first} = $element.key")
            writer.write("let ${nestedKeyValueName.second} = $element.value")

            val entry = resolvedMemberName.toString().indexAdvancedBy1(index)
            writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"$entry\"))")
            when (valueTargetShape) {
                is MapShape -> {
                    renderMapKey(nestedKeyValueName, resolvedCodingKeys, mapShape, nestedContainer, level)
                    renderMapNestedValue(nestedKeyValueName, resolvedCodingKeys, mapShape, valueTargetShape, nestedContainer, level) { nestedValueContainer ->
                        renderFlattenedMapMemberItem(nestedKeyValueName.second, mapShape.value, valueTargetShape, nestedValueContainer, level + 1)
                    }
                }
                is CollectionShape -> {
                    renderMapKey(nestedKeyValueName, resolvedCodingKeys, mapShape, nestedContainer, level)
                    renderMapNestedValue(nestedKeyValueName, resolvedCodingKeys, mapShape, valueTargetShape, nestedContainer, level) { nestedValueContainer ->
                        renderListMemberItems(nestedKeyValueName.second, valueTargetShape, nestedValueContainer, level + 1)
                    }
                }
                is TimestampShape -> {
                    renderMapKey(nestedKeyValueName, resolvedCodingKeys, mapShape, nestedContainer, level)
                    renderMapValue(nestedKeyValueName, resolvedCodingKeys, mapShape, nestedContainer, level) { valueContainer ->
                        val format = TimeStampFormat.determineTimestampFormat(mapShape.value, valueTargetShape, defaultTimestampFormat)
                        writer.write("try $valueContainer.encode(TimestampWrapper(${nestedKeyValueName.second}, format: .$format), forKey: Key(\"\"))")
                    }
                }
                is BlobShape -> {
                    renderMapKey(nestedKeyValueName, resolvedCodingKeys, mapShape, nestedContainer, level)
                    renderMapValue(nestedKeyValueName, resolvedCodingKeys, mapShape, nestedContainer, level) { valueContainer ->
                        renderBlobMemberName(nestedKeyValueName.second, "", valueContainer, false)
                    }
                }
                else -> {
                    renderMapKey(nestedKeyValueName, resolvedCodingKeys, mapShape, nestedContainer, level)
                    renderMapValue(nestedKeyValueName, resolvedCodingKeys, mapShape, nestedContainer, level)
                }
            }
        }
    }

    private fun renderMapKey(
        nestedKeyValueName: Pair<String, String>,
        resolvedCodingKeys: Pair<XMLNameTraitGenerator, XMLNameTraitGenerator>,
        mapShape: MapShape,
        nestedContainer: String,
        level: Int
    ) {
        val nestedKeyContainer = "keyContainer$level"
        writer.write("var $nestedKeyContainer = $nestedContainer.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedCodingKeys.first}\"))")
        writer.write("try $nestedKeyContainer.encode(${nestedKeyValueName.first}, forKey: Key(\"\"))")
    }

    private fun renderMapValue(
        nestedKeyValueName: Pair<String, String>,
        resolvedCodingKeys: Pair<XMLNameTraitGenerator, XMLNameTraitGenerator>,
        mapShape: MapShape,
        entryContainerName: String,
        level: Int,
        customValueRenderer: ((String) -> Unit)? = null
    ) {
        val valueContainerName = "valueContainer$level"
        writer.write("var $valueContainerName = $entryContainerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedCodingKeys.second}\"))")
        if (customValueRenderer != null) {
            customValueRenderer(valueContainerName)
        } else {
            writer.write("try $valueContainerName.encode(${nestedKeyValueName.second}, forKey: Key(\"\"))")
        }
    }

    private fun renderMapNestedValue(
        nestedKeyValueName: Pair<String, String>,
        resolvedCodingKeys: Pair<XMLNameTraitGenerator, XMLNameTraitGenerator>,
        mapShape: MapShape,
        valueTargetShape: Shape,
        entryContainerName: String,
        level: Int,
        nextRenderer: (String) -> Unit
    ) {
        val isBoxed = ctx.symbolProvider.toSymbol(valueTargetShape).isBoxed()
        val nextContainer = "valueContainer${level + 1}"
        if (isBoxed && !(valueTargetShape is SetShape)) {
            writer.openBlock("if let ${nestedKeyValueName.second} = ${nestedKeyValueName.second} {", "}") {
                writer.write("var $nextContainer = $entryContainerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedCodingKeys.second}\"))")
                nextRenderer(nextContainer)
            }
        } else {
            // Todo: Write a unit test for this
            writer.openBlock("if let ${nestedKeyValueName.second} = ${nestedKeyValueName.second} {", "}") {
                writer.write("var $nextContainer = $entryContainerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedCodingKeys.second}\"))")
                nextRenderer(nextContainer)
            }
        }
    }

    fun renderTimestampMember(member: MemberShape, memberTarget: TimestampShape, containerName: String) {
        val symbol = ctx.symbolProvider.toSymbol(memberTarget)
        val memberName = ctx.symbolProvider.toMemberName(member)
        val resolvedMemberName = XMLNameTraitGenerator.construct(member, memberName)
        val format = TimeStampFormat.determineTimestampFormat(member, memberTarget, defaultTimestampFormat)
        val isBoxed = symbol.isBoxed()
        val encodeLine = "try $containerName.encode(TimestampWrapper($memberName, format: .$format), forKey: Key(\"$resolvedMemberName\"))"
        if (isBoxed) {
            writer.openBlock("if let $memberName = $memberName {", "}") {
                writer.write(encodeLine)
            }
        } else {
            writer.write(encodeLine)
        }
    }

    fun renderBlobMember(member: MemberShape, memberTarget: BlobShape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val resolvedMemberName = XMLNameTraitGenerator.construct(member, member.memberName).toString()
        val symbol = ctx.symbolProvider.toSymbol(memberTarget)
        val isBoxed = symbol.isBoxed()
        renderBlobMemberName(memberName, resolvedMemberName, containerName, isBoxed)
    }

    private fun renderBlobMemberName(memberName: String, resolvedMemberName: String, containerName: String, isBoxed: Boolean) {
        val encodeLine = "try $containerName.encode($memberName.base64EncodedString(), forKey: Key(\"$resolvedMemberName\"))"
        if (isBoxed) {
            writer.openBlock("if let $memberName = $memberName {", "}") {
                writer.write(encodeLine)
            }
        } else {
            writer.write(encodeLine)
        }
    }

    fun renderScalarMember(member: MemberShape, memberTarget: Shape, containerName: String) {
        val symbol = ctx.symbolProvider.toSymbol(memberTarget)
        val memberName = ctx.symbolProvider.toMemberName(member)
        val resolvedMemberName = XMLNameTraitGenerator.construct(member, member.memberName).toString()
        val isBoxed = symbol.isBoxed()
        if (isBoxed) {
            writer.openBlock("if let $memberName = $memberName {", "}") {
                renderItem(writer, containerName, memberName, resolvedMemberName)
            }
        } else {
            if (MemberShapeEncodeConstants.primitiveSymbols.contains(memberTarget.type)) {
                val defaultValue = getDefaultValueOfShapeType(memberTarget.type)
                writer.openBlock("if $memberName != $defaultValue {", "}") {
                    writer.write("try $containerName.encode($memberName, forKey: Key(\"$resolvedMemberName\"))")
                }
            } else {
                writer.write("try $containerName.encode($memberName, forKey: Key(\"$resolvedMemberName\"))")
            }
        }
    }

    private fun renderItem(writer: SwiftWriter, containerName: String, memberName: String, resolvedMemberName: String) {
        writer.write("try $containerName.encode($memberName, forKey: Key(\"${resolvedMemberName}\"))")
    }
}
