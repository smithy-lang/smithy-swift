/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration.serde.json

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
import software.amazon.smithy.swift.codegen.integration.serde.TimeStampFormat.Companion.determineTimestampFormat
import software.amazon.smithy.swift.codegen.integration.serde.getDefaultValueOfShapeType
import software.amazon.smithy.swift.codegen.integration.serde.xml.trait.XMLNameTraitGenerator
import software.amazon.smithy.swift.codegen.integration.serde.xml.trait.XMLNamespaceTraitGenerator
import software.amazon.smithy.swift.codegen.isBoxed

abstract class MemberShapeEncodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeEncodeGeneratable {

    val xmlNamespaces = mutableSetOf<String>()

    fun renderListMember(
        member: MemberShape,
        memberTarget: CollectionShape,
        containerName: String
    ) {
        val originalMemberName = member.memberName
        val memberName = ctx.symbolProvider.toMemberName(member)
        val resolvedMemberName = XMLNameTraitGenerator.construct(member, originalMemberName)
        val nestedContainer = "${memberName}Container"
        if (member.hasTrait(XmlFlattenedTrait::class.java)) {
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
            XMLNamespaceTraitGenerator.construct(member)?.render(writer, nestedContainer)?.appendKey(xmlNamespaces)
            renderListMemberItems(memberName, memberTarget, nestedContainer)
        }
    }

    private fun renderListMemberItems(
        memberName: String,
        memberTarget: CollectionShape,
        containerName: String,
        level: Int = 0
    ) {
        val nestedMember = memberTarget.member
        val nestedMemberResolvedName = XMLNameTraitGenerator.construct(nestedMember, "member").toString()

        val nestedMemberTarget = ctx.model.expectShape(memberTarget.member.target)
        val nestedMemberTargetName = "${nestedMemberTarget.id.name.toLowerCase()}$level"
        writer.openBlock("for $nestedMemberTargetName in $memberName {", "}") {
            when (nestedMemberTarget) {
                is CollectionShape -> {
                    renderNestedListEntryMember(nestedMemberTargetName, nestedMemberTarget, nestedMember, nestedMemberResolvedName, containerName, level)
                }
                is MapShape -> {
                    val nestedContainerName = "${memberName}Container$level"
                    writer.write("var $nestedContainerName = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"${nestedMemberResolvedName}\"))")
                    writer.openBlock("if let $nestedMemberTargetName = $nestedMemberTargetName {", "}") {
                        renderWrappedMapMemberItem(nestedMemberTargetName, nestedMemberTarget, nestedContainerName, level)
                    }
                }
                is TimestampShape -> {
                    val format = determineTimestampFormat(nestedMember, nestedMemberTarget, defaultTimestampFormat)
                    val encodeValue = "TimestampWrapper($nestedMemberTargetName, format: .$format), forKey: Key(\"${nestedMemberResolvedName}\")"
                    writer.write("try $containerName.encode($encodeValue)")
                }
                else -> {
                    val nestedMemberNamespaceTraitGenerator = XMLNamespaceTraitGenerator.construct(nestedMember)
                    val nestedContainerName = "${memberName}Container$level"
                    renderItem(writer, nestedMemberNamespaceTraitGenerator, nestedContainerName, containerName, nestedMemberTargetName, nestedMemberTarget, nestedMemberResolvedName)
                }
            }
        }
    }

    private fun renderNestedListEntryMember(nestedMemberTargetName: String, nestedMemberTarget: CollectionShape, nestedMember: MemberShape, nestedMemberResolvedName: String, containerName: String, level: Int) {
        var nestedContainerName = "${nestedMemberTargetName}Container$level"
        writer.write("var $nestedContainerName = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"${nestedMemberResolvedName}\"))")
        XMLNamespaceTraitGenerator.construct(nestedMember)?.render(writer, nestedContainerName)?.appendKey(xmlNamespaces)
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
        val defaultMemberName = if (level == 0) memberName else "member"
        val resolvedMemberName = XMLNameTraitGenerator.construct(member, defaultMemberName)
        val nestedContainerName = "${memberName}Container$level"

        writer.openBlock("for $nestedMemberTargetName in $memberName {", "}") {
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
                    val format = determineTimestampFormat(nestedMember, nestedMemberTarget, defaultTimestampFormat)
                    XMLNamespaceTraitGenerator.construct(member)?.render(writer, nestedContainerName)?.appendKey(xmlNamespaces)
                    val encodeValue = "TimestampWrapper($nestedMemberTargetName, format: .$format), forKey: Key(\"\")"
                    writer.write("try $nestedContainerName.encode($encodeValue)")
                }
                else -> {
                    writer.write("var $nestedContainerName = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"$resolvedMemberName\"))")
                    XMLNamespaceTraitGenerator.construct(member)?.render(writer, nestedContainerName)?.appendKey(xmlNamespaces)
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
        XMLNamespaceTraitGenerator.construct(member)?.render(writer, nestedContainerName)?.appendKey(xmlNamespaces)
        renderFlattenedListMemberItems(nestedMemberTargetName, nestedMember, nestedMemberTarget, nestedContainerName, level + 1)
    }

    fun renderMapMember(member: MemberShape, memberTarget: MapShape, containerName: String) {
        val originalMemberName = member.memberName
        val memberName = ctx.symbolProvider.toMemberName(member)
        val resolvedMemberName = XMLNameTraitGenerator.construct(member, originalMemberName)

        if (member.hasTrait(XmlFlattenedTrait::class.java)) {
            writer.openBlock("if $memberName.isEmpty {", "} else {") {
                writer.write("let _ =  $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"$resolvedMemberName\"))")
            }
            writer.indent()
            renderFlattenedMapMemberItem(memberName, member, memberTarget, containerName)
            writer.dedent().write("}")
        } else {
            val nestedContainer = "${resolvedMemberName}Container"
            writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"$resolvedMemberName\"))")
            XMLNamespaceTraitGenerator.construct(member)?.render(writer, nestedContainer)?.appendKey(xmlNamespaces)
            renderWrappedMapMemberItem(memberName, memberTarget, nestedContainer)
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
        writer.openBlock("for (${nestedKeyValueName.first}, ${nestedKeyValueName.second}) in $memberName {", "}") {
            writer.write("var $entryContainerName = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"entry\"))")
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
                        val format = determineTimestampFormat(mapShape.value, valueTargetShape, defaultTimestampFormat)
                        writer.write("try $valueContainer.encode(TimestampWrapper(${nestedKeyValueName.second}, format: .$format), forKey: Key(\"\"))")
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

        val resolvedMemberName = if (level == 0) XMLNameTraitGenerator.construct(member, memberName) else "entry"

        val resolvedCodingKeys = Pair(
            XMLNameTraitGenerator.construct(mapShape.key, "key"),
            XMLNameTraitGenerator.construct(mapShape.value, "value")
        )

        val nestedKeyValueName = Pair("${keyTargetShape.id.name.toLowerCase()}Key$level", "${valueTargetShape.id.name.toLowerCase()}Value$level")
        val nestedContainer = "nestedContainer$level"
        writer.openBlock("for (${nestedKeyValueName.first}, ${nestedKeyValueName.second}) in $memberName {", "}") {
            writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"$resolvedMemberName\"))")
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
                        val format = determineTimestampFormat(mapShape.value, valueTargetShape, defaultTimestampFormat)
                        writer.write("try $valueContainer.encode(TimestampWrapper(${nestedKeyValueName.second}, format: .$format), forKey: Key(\"\"))")
                    }
                }
                else -> {
                    if (level == 0) {
                        val memberNamespaceTraitGenerator = XMLNamespaceTraitGenerator.construct(member)
                        memberNamespaceTraitGenerator?.render(writer, nestedContainer)?.appendKey(xmlNamespaces)
                    }
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
        XMLNamespaceTraitGenerator.construct(mapShape.key)?.render(writer, nestedKeyContainer)?.appendKey(xmlNamespaces)
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
        XMLNamespaceTraitGenerator.construct(mapShape.value)?.render(writer, valueContainerName)?.appendKey(xmlNamespaces)
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
        val nextContainer = "valueContainer${level + 1}"
        writer.write("var $nextContainer = $entryContainerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedCodingKeys.second}\"))")
        XMLNamespaceTraitGenerator.construct(mapShape.value)?.render(writer, nextContainer)?.appendKey(xmlNamespaces)
        nextRenderer(nextContainer)
    }

    fun renderTimestampMember(member: MemberShape, memberTarget: TimestampShape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val originalMemberName = member.memberName
        val resolvedMemberName = XMLNameTraitGenerator.construct(member, originalMemberName)
        val format = determineTimestampFormat(member, memberTarget, defaultTimestampFormat)
        val encodeLine = "try $containerName.encode(TimestampWrapper($memberName, format: .$format), forKey: Key(\"$resolvedMemberName\"))"
        writer.write(encodeLine)
    }

    fun renderScalarMember(member: MemberShape, memberTarget: Shape, containerName: String) {
        val symbol = ctx.symbolProvider.toSymbol(memberTarget)
        val originalMemberName = member.memberName
        val memberName = ctx.symbolProvider.toMemberName(member)
        val resolvedMemberName = XMLNameTraitGenerator.construct(member, originalMemberName).toString()
        val isBoxed = symbol.isBoxed()
        if (isBoxed) {
            writer.openBlock("if let $memberName = $memberName {", "}") {
                val namespaceTraitGenerator = XMLNamespaceTraitGenerator.construct(member)
                val nestedContainerName = "${memberName}Container"
                renderItem(writer, namespaceTraitGenerator, nestedContainerName, containerName, memberName, memberTarget, resolvedMemberName)
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
    fun renderEncodeAssociatedType(member: MemberShape, memberTarget: Shape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val originalMemberName = member.memberName
        val namespaceTraitGenerator = XMLNamespaceTraitGenerator.construct(member)
        val resolvedMemberName = XMLNameTraitGenerator.construct(member, originalMemberName).toString()
        val nestedContainerName = "${memberName}Container"
        renderItem(writer, namespaceTraitGenerator, nestedContainerName, containerName, memberName, memberTarget, resolvedMemberName)

    }

    private fun renderItem(writer: SwiftWriter, XMLNamespaceTraitGenerator: XMLNamespaceTraitGenerator?, nestedContainerName: String, containerName: String, memberName: String, memberTarget: Shape, resolvedMemberName: String) {
        var renderableMemberName = memberName
        if (MemberShapeEncodeConstants.floatingPointPrimitiveSymbols.contains(memberTarget.type)) {
            renderableMemberName = "String($memberName)"
        }
        XMLNamespaceTraitGenerator?.let {
            writer.write("var $nestedContainerName = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedMemberName}\"))")
            writer.write("try $nestedContainerName.encode($renderableMemberName, forKey: Key(\"\"))")
            it.render(writer, nestedContainerName)
            it.appendKey(xmlNamespaces)
        } ?: run {
            writer.write("try $containerName.encode($renderableMemberName, forKey: Key(\"${resolvedMemberName}\"))")
        }
    }
}
