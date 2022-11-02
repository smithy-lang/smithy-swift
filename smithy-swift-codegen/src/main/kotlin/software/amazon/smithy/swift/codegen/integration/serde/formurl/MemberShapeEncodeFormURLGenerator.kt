/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

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
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeEncodeConstants
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeEncodeGeneratable
import software.amazon.smithy.swift.codegen.integration.serde.TimestampEncodeGenerator
import software.amazon.smithy.swift.codegen.integration.serde.TimestampHelpers
import software.amazon.smithy.swift.codegen.integration.serde.getDefaultValueOfShapeType
import software.amazon.smithy.swift.codegen.model.isBoxed

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
        val resolvedMemberName = customizations.customNameTraitGenerator(member, member.memberName)
        val nestedContainer = "${memberName}Container"
        writer.openBlock("if let $memberName = $memberName {", "}") {
            writer.openBlock("if !$memberName.isEmpty {", "}") {
                if (member.hasTrait(XmlFlattenedTrait::class.java) || customizations.alwaysUsesFlattenedCollections()) {
                    renderFlattenedListMemberItems(memberName, member, memberTarget, containerName)
                } else {
                    writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: \$N.self, forKey: \$N(\"$resolvedMemberName\"))", ClientRuntimeTypes.Serde.Key, ClientRuntimeTypes.Serde.Key)
                    renderListMemberItems(memberName, memberTarget, nestedContainer)
                }
            }
            if (customizations.shouldSerializeEmptyLists()) {
                writer.openBlock("else {", "}") {
                    writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: \$N.self, forKey: \$N(\"$resolvedMemberName\"))", ClientRuntimeTypes.Serde.Key, ClientRuntimeTypes.Serde.Key)
                    writer.write("try $nestedContainer.encode(\"\", forKey: \$N(\"\"))", ClientRuntimeTypes.Serde.Key)
                }
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
        val nestedMemberResolvedName = customizations.customNameTraitGenerator(nestedMember, "member").indexAdvancedBy1("index$level")

        val nestedMemberTarget = ctx.model.expectShape(memberTarget.member.target)
        val nestedMemberTargetName = "${nestedMemberTarget.id.name.toLowerCase()}$level"
        writer.openBlock("for (index$level, $nestedMemberTargetName) in $memberName.enumerated() {", "}") {
            when (nestedMemberTarget) {
                is CollectionShape -> {
                    val isBoxed = ctx.symbolProvider.toSymbol(memberTarget.member).isBoxed()
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
                    writer.write("var $nestedContainerName = $containerName.nestedContainer(keyedBy: \$N.self, forKey: \$N(\"${nestedMemberResolvedName}\"))", ClientRuntimeTypes.Serde.Key, ClientRuntimeTypes.Serde.Key)
                    writer.openBlock("if let $nestedMemberTargetName = $nestedMemberTargetName {", "}") {
                        renderWrappedMapMemberItem(nestedMemberTargetName, nestedMemberTarget, nestedContainerName, level)
                    }
                }
                is TimestampShape -> {
                    val codingKey = "${ClientRuntimeTypes.Serde.Key}(\"${nestedMemberResolvedName}\")"
                    val code = TimestampEncodeGenerator(
                        containerName,
                        nestedMemberTargetName,
                        codingKey,
                        TimestampHelpers.getTimestampFormat(nestedMember, nestedMemberTarget, defaultTimestampFormat)
                    ).generate()
                    writer.write(code)
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
        writer.write("var $nestedContainerName = $containerName.nestedContainer(keyedBy: \$N.self, forKey: \$N(\"${nestedMemberResolvedName}\"))", ClientRuntimeTypes.Serde.Key, ClientRuntimeTypes.Serde.Key)
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
        val resolvedMemberName = customizations.customNameTraitGenerator(member, defaultMemberName).indexAdvancedBy1("index$level")
        val nestedContainerName = "${memberName}Container$level"

        writer.openBlock("for (index$level, $nestedMemberTargetName) in $memberName.enumerated() {", "}") {
            when (nestedMemberTarget) {
                is CollectionShape -> {
                    val isBoxed = ctx.symbolProvider.toSymbol(memberTarget.member).isBoxed()
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
                    writer.write("var $nestedContainerName = $containerName.nestedContainer(keyedBy: \$N.self, forKey: \$N(\"$resolvedMemberName\"))", ClientRuntimeTypes.Serde.Key, ClientRuntimeTypes.Serde.Key)
                    val codingKey = "${ClientRuntimeTypes.Serde.Key}(\"\")"
                    val code = TimestampEncodeGenerator(
                        nestedContainerName,
                        nestedMemberTargetName,
                        codingKey,
                        TimestampHelpers.getTimestampFormat(nestedMember, nestedMemberTarget, defaultTimestampFormat)
                    ).generate()
                    writer.write(code)
                }
                is BlobShape -> {
                    renderBlobMemberName(nestedMemberTargetName, resolvedMemberName, containerName, false)
                }
                else -> {
                    writer.write("var $nestedContainerName = $containerName.nestedContainer(keyedBy: \$N.self, forKey: \$N(\"$resolvedMemberName\"))", ClientRuntimeTypes.Serde.Key, ClientRuntimeTypes.Serde.Key)
                    writer.write("try $nestedContainerName.encode($nestedMemberTargetName, forKey: \$N(\"\"))", ClientRuntimeTypes.Serde.Key)
                }
            }
        }
    }
    private fun renderFlattenedListContainer(nestedMemberTargetName: String, nestedMemberTarget: CollectionShape, nestedMember: MemberShape, memberName: String, member: MemberShape, containerName: String, level: Int) {
        var nestedContainerName = "${nestedMemberTargetName}Container$level"
        val defaultMemberName = if (level == 0) memberName else "member"
        val memberResolvedName = customizations.customNameTraitGenerator(member, defaultMemberName)
        writer.write("var $nestedContainerName = $containerName.nestedContainer(keyedBy: \$N.self, forKey: \$N(\"${memberResolvedName}\"))", ClientRuntimeTypes.Serde.Key, ClientRuntimeTypes.Serde.Key)
        renderFlattenedListMemberItems(nestedMemberTargetName, nestedMember, nestedMemberTarget, nestedContainerName, level + 1)
    }

    fun renderMapMember(member: MemberShape, memberTarget: MapShape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val resolvedMemberName = customizations.customNameTraitGenerator(member, member.memberName)

        writer.openBlock("if let $memberName = $memberName {", "}") {
            if (member.hasTrait(XmlFlattenedTrait::class.java) || customizations.alwaysUsesFlattenedCollections()) {
                writer.openBlock("if !$memberName.isEmpty {", "}") {
                    renderFlattenedMapMemberItem(memberName, member, memberTarget, containerName)
                }
            } else {
                val nestedContainer = "${memberName}Container"
                writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: \$N.self, forKey: \$N(\"$resolvedMemberName\"))", ClientRuntimeTypes.Serde.Key, ClientRuntimeTypes.Serde.Key)
                renderWrappedMapMemberItem(memberName, memberTarget, nestedContainer)
            }
        }
    }

    private fun renderWrappedMapMemberItem(memberName: String, mapShape: MapShape, containerName: String, level: Int = 0) {
        val keyTargetShape = ctx.model.expectShape(mapShape.key.target)
        val valueTargetShape = ctx.model.expectShape(mapShape.value.target)

        val resolvedCodingKeys = Pair(
            customizations.customNameTraitGenerator(mapShape.key, "key"),
            customizations.customNameTraitGenerator(mapShape.value, "value")
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
            writer.write("var $entryContainerName = $containerName.nestedContainer(keyedBy: \$N.self, forKey: \$N(\"$entry\"))", ClientRuntimeTypes.Serde.Key, ClientRuntimeTypes.Serde.Key)
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
                        val codingKey = "${ClientRuntimeTypes.Serde.Key}(\"\")"
                        val code = TimestampEncodeGenerator(
                            valueContainer,
                            nestedKeyValueName.second,
                            codingKey,
                            TimestampHelpers.getTimestampFormat(mapShape.value, valueTargetShape, defaultTimestampFormat)
                        ).generate()
                        writer.write(code)
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

        val resolvedMemberName = if (level == 0) customizations.customNameTraitGenerator(member, member.memberName) else "entry"

        val resolvedCodingKeys = Pair(
            customizations.customNameTraitGenerator(mapShape.key, "key"),
            customizations.customNameTraitGenerator(mapShape.value, "value")
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
            writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: \$N.self, forKey: \$N(\"$entry\"))", ClientRuntimeTypes.Serde.Key, ClientRuntimeTypes.Serde.Key)
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
                        val codingKey = "${ClientRuntimeTypes.Serde.Key}(\"\")"
                        val code = TimestampEncodeGenerator(
                            valueContainer,
                            nestedKeyValueName.second,
                            codingKey,
                            TimestampHelpers.getTimestampFormat(mapShape.value, valueTargetShape, defaultTimestampFormat)
                        ).generate()
                        writer.write(code)
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
        resolvedCodingKeys: Pair<String, String>,
        mapShape: MapShape,
        nestedContainer: String,
        level: Int
    ) {
        val nestedKeyContainer = "keyContainer$level"
        writer.write("var $nestedKeyContainer = $nestedContainer.nestedContainer(keyedBy: \$N.self, forKey: \$N(\"${resolvedCodingKeys.first}\"))", ClientRuntimeTypes.Serde.Key, ClientRuntimeTypes.Serde.Key)
        writer.write("try $nestedKeyContainer.encode(${nestedKeyValueName.first}, forKey: \$N(\"\"))", ClientRuntimeTypes.Serde.Key)
    }

    private fun renderMapValue(
        nestedKeyValueName: Pair<String, String>,
        resolvedCodingKeys: Pair<String, String>,
        mapShape: MapShape,
        entryContainerName: String,
        level: Int,
        customValueRenderer: ((String) -> Unit)? = null
    ) {
        val valueContainerName = "valueContainer$level"
        writer.write("var $valueContainerName = $entryContainerName.nestedContainer(keyedBy: \$N.self, forKey: \$N(\"${resolvedCodingKeys.second}\"))", ClientRuntimeTypes.Serde.Key, ClientRuntimeTypes.Serde.Key)
        if (customValueRenderer != null) {
            customValueRenderer(valueContainerName)
        } else {
            writer.write("try $valueContainerName.encode(${nestedKeyValueName.second}, forKey: \$N(\"\"))", ClientRuntimeTypes.Serde.Key)
        }
    }

    private fun renderMapNestedValue(
        nestedKeyValueName: Pair<String, String>,
        resolvedCodingKeys: Pair<String, String>,
        mapShape: MapShape,
        valueTargetShape: Shape,
        entryContainerName: String,
        level: Int,
        nextRenderer: (String) -> Unit
    ) {
        val nextContainer = "valueContainer${level + 1}"
        writer.write("var $nextContainer = $entryContainerName.nestedContainer(keyedBy: \$N.self, forKey: \$N(\"${resolvedCodingKeys.second}\"))", ClientRuntimeTypes.Serde.Key, ClientRuntimeTypes.Serde.Key)
        nextRenderer(nextContainer)
    }

    fun renderTimestampMember(member: MemberShape, memberTarget: TimestampShape, containerName: String) {
        val symbol = ctx.symbolProvider.toSymbol(memberTarget)
        val memberName = ctx.symbolProvider.toMemberName(member)
        val resolvedMemberName = customizations.customNameTraitGenerator(member, memberName)
        val isBoxed = symbol.isBoxed()
        val codingKey = "${ClientRuntimeTypes.Serde.Key}(\"$resolvedMemberName\")"
        val encodeLine = TimestampEncodeGenerator(
            containerName,
            memberName,
            codingKey,
            TimestampHelpers.getTimestampFormat(member, memberTarget, defaultTimestampFormat)
        ).generate()
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
        val resolvedMemberName = customizations.customNameTraitGenerator(member, member.memberName)
        val symbol = ctx.symbolProvider.toSymbol(memberTarget)
        val isBoxed = symbol.isBoxed()
        renderBlobMemberName(memberName, resolvedMemberName, containerName, isBoxed)
    }

    private fun renderBlobMemberName(memberName: String, resolvedMemberName: String, containerName: String, isBoxed: Boolean) {
        val encodeLine = "try $containerName.encode($memberName.base64EncodedString(), forKey: ${ClientRuntimeTypes.Serde.Key}(\"$resolvedMemberName\"))"
        if (isBoxed) {
            writer.openBlock("if let $memberName = $memberName {", "}") {
                writer.write(encodeLine)
            }
        } else {
            writer.write(encodeLine)
        }
    }

    fun renderScalarMember(member: MemberShape, memberTarget: Shape, containerName: String) {
        val symbol = ctx.symbolProvider.toSymbol(member)
        val memberName = ctx.symbolProvider.toMemberName(member)
        val resolvedMemberName = customizations.customNameTraitGenerator(member, member.memberName)
        val isBoxed = symbol.isBoxed()
        if (isBoxed) {
            writer.openBlock("if let $memberName = $memberName {", "}") {
                renderItem(writer, containerName, memberName, resolvedMemberName)
            }
        } else {
            if (MemberShapeEncodeConstants.primitiveSymbols.contains(memberTarget.type)) {
                val defaultValue = getDefaultValueOfShapeType(memberTarget.type)
                writer.openBlock("if $memberName != $defaultValue {", "}") {
                    if (MemberShapeEncodeConstants.floatingPointPrimitiveSymbols.contains(memberTarget.type)) {
                        writer.write(
                            "try $containerName.encode(\$N($memberName), forKey: \$N(\"$resolvedMemberName\"))",
                            SwiftTypes.String, ClientRuntimeTypes.Serde.Key
                        )
                    } else {
                        writer.write("try $containerName.encode($memberName, forKey: \$N(\"$resolvedMemberName\"))", ClientRuntimeTypes.Serde.Key)
                    }
                }
            } else {
                writer.write("try $containerName.encode($memberName, forKey: \$N(\"$resolvedMemberName\"))", ClientRuntimeTypes.Serde.Key)
            }
        }
    }

    private fun renderItem(writer: SwiftWriter, containerName: String, memberName: String, resolvedMemberName: String) {
        writer.write("try $containerName.encode($memberName, forKey: \$N(\"${resolvedMemberName}\"))", ClientRuntimeTypes.Serde.Key)
    }
}
