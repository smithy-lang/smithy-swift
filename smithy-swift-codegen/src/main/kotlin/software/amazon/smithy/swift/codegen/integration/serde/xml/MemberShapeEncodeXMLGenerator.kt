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
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.model.traits.XmlFlattenedTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
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

    private val primitiveSymbols: MutableSet<ShapeType> = hashSetOf(
        ShapeType.INTEGER, ShapeType.BYTE, ShapeType.SHORT,
        ShapeType.LONG, ShapeType.FLOAT, ShapeType.DOUBLE, ShapeType.BOOLEAN
    )

    fun renderListMember(
        member: MemberShape,
        memberTarget: CollectionShape,
        containerName: String
    ) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val resolvedMemberName = XMLNameTraitGenerator.construct(member, memberName)
        val nestedContainer = "${memberName}Container"
        writer.openBlock("if let $memberName = $memberName {", "}") {
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
                    val format = determineTimestampFormat(nestedMember, defaultTimestampFormat)
                    val encodeValue = "TimestampWrapper($nestedMemberTargetName, format: .$format), forKey: Key(\"${nestedMemberResolvedName}\")"
                    writer.write("try $containerName.encode($encodeValue)")
                }
                else -> {
                    val nestedMemberNamespaceTraitGenerator = XMLNamespaceTraitGenerator.construct(nestedMember)
                    val nestedContainerName = "${memberName}Container$level"
                    renderItem(writer, nestedMemberNamespaceTraitGenerator, nestedContainerName, containerName, nestedMemberTargetName, nestedMemberResolvedName)
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
                    val format = determineTimestampFormat(nestedMember, defaultTimestampFormat)
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
        val memberName = ctx.symbolProvider.toMemberName(member)
        val resolvedMemberName = XMLNameTraitGenerator.construct(member, memberName)

        writer.openBlock("if let $memberName = $memberName {", "}") {
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
    }

    private fun renderWrappedMapMemberItem(memberName: String, mapShape: MapShape, containerName: String, level: Int = 0) {
        val keyTargetShape = ctx.model.expectShape(mapShape.key.target)
        val valueTargetShape = ctx.model.expectShape(mapShape.value.target)

        val resolvedCodingKeys = Pair(
            XMLNameTraitGenerator.construct(mapShape.key, "key"),
            XMLNameTraitGenerator.construct(mapShape.value, "value")
        )

        val nestedKeyValueName = Pair("${keyTargetShape.id.name.toLowerCase()}Key$level", "${valueTargetShape.id.name.toLowerCase()}Value$level")
        writer.openBlock("for (${nestedKeyValueName.first}, ${nestedKeyValueName.second}) in $memberName {", "}") {
            when (valueTargetShape) {
                is MapShape -> {
                    renderWrappedNestedMapEntry(nestedKeyValueName, resolvedCodingKeys, valueTargetShape, mapShape, containerName, level)
                }
                is CollectionShape -> {
                    var entryContainerName = "entryContainer$level"
                    writer.write("var $entryContainerName = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"entry\"))")

                    val mapShapeKeyNamespaceTraitGenerator = XMLNamespaceTraitGenerator.construct(mapShape.key)
                    val mapShapeValueNamespaceTraitGenerator = XMLNamespaceTraitGenerator.construct(mapShape.value)

                    writer.write("var keyContainer = $entryContainerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedCodingKeys.first}\"))")
                    mapShapeKeyNamespaceTraitGenerator?.render(writer, "keyContainer")?.appendKey(xmlNamespaces)
                    writer.write("try keyContainer.encode(${nestedKeyValueName.first}, forKey: Key(\"\"))")

                    val isBoxed = ctx.symbolProvider.toSymbol(valueTargetShape).isBoxed()
                    if (isBoxed && !(valueTargetShape is SetShape)) {
                        writer.openBlock("if let ${nestedKeyValueName.second} = ${nestedKeyValueName.second} {", "}") {
                            writer.write("var valueContainer = $entryContainerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedCodingKeys.second}\"))")
                            mapShapeValueNamespaceTraitGenerator?.render(writer, "valueContainer")?.appendKey(xmlNamespaces)
                            renderListMemberItems(nestedKeyValueName.second, valueTargetShape, "valueContainer")
                        }
                    } else {
                        // Todo: Write a unit test for this
                        writer.write("var valueContainer = $entryContainerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedCodingKeys.second}\"))")
                        mapShapeValueNamespaceTraitGenerator?.render(writer, "valueContainer")?.appendKey(xmlNamespaces)
                        renderListMemberItems(nestedKeyValueName.second, valueTargetShape, "valueContainer")
                    }
                }
                else -> {
                    val mapShapeKeyNamespaceTraitGenerator = XMLNamespaceTraitGenerator.construct(mapShape.key)
                    val mapShapeValueNamespaceTraitGenerator = XMLNamespaceTraitGenerator.construct(mapShape.value)
                    writer.write("var entry = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"entry\"))")

                    writer.write("var keyContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedCodingKeys.first}\"))")
                    mapShapeKeyNamespaceTraitGenerator?.render(writer, "keyContainer")?.appendKey(xmlNamespaces)
                    writer.write("try keyContainer.encode(${nestedKeyValueName.first}, forKey: Key(\"\"))")

                    writer.write("var valueContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedCodingKeys.second}\"))")
                    mapShapeValueNamespaceTraitGenerator?.render(writer, "valueContainer")?.appendKey(xmlNamespaces)
                    writer.write("try valueContainer.encode(${nestedKeyValueName.second}, forKey: Key(\"\"))")
                }
            }
        }
    }

    private fun renderWrappedNestedMapEntry(
        nestedKeyValueName: Pair<String, String>,
        resolvedCodingKeys: Pair<XMLNameTraitGenerator, XMLNameTraitGenerator>,
        valueTargetShape: MapShape,
        mapShape: MapShape,
        containerName: String,
        level: Int
    ) {
        val keyName = nestedKeyValueName.first
        val valueName = nestedKeyValueName.second

        val nestedContainer = "nestedMapEntryContainer$level"
        writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"entry\"))")

        val nestedKeyContainer = "nestedKeyContainer$level"
        writer.write("var $nestedKeyContainer = $nestedContainer.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedCodingKeys.first}\"))")
        XMLNamespaceTraitGenerator.construct(mapShape.key)?.render(writer, nestedKeyContainer)?.appendKey(xmlNamespaces)
        writer.write("try $nestedKeyContainer.encode($keyName, forKey: Key(\"\"))")

        writer.openBlock("if let $valueName = $valueName {", "}") {
            val nextContainer = "nestedMapEntryContainer${level + 1}"
            writer.write("var $nextContainer = $nestedContainer.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedCodingKeys.second}\"))")
            XMLNamespaceTraitGenerator.construct(mapShape.value)?.render(writer, nextContainer)?.appendKey(xmlNamespaces)
            renderWrappedMapMemberItem(valueName, valueTargetShape, nextContainer, level + 1)
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
                    renderFlattenedNestedMapKey(nestedContainer, resolvedCodingKeys, mapShape, nestedKeyValueName, level)
                    renderFlattenedNestedMapValue(nestedKeyValueName, resolvedCodingKeys, mapShape, valueTargetShape, nestedContainer, level) { nestedValueContainer ->
                        renderFlattenedMapMemberItem(nestedKeyValueName.second, mapShape.value, valueTargetShape, nestedValueContainer, level + 1)
                    }
                }
                is CollectionShape -> {
                    renderFlattenedNestedMapKey(nestedContainer, resolvedCodingKeys, mapShape, nestedKeyValueName, level)
                    renderFlattenedNestedMapValue(nestedKeyValueName, resolvedCodingKeys, mapShape, valueTargetShape, nestedContainer, level) { nestedValueContainer ->
                        renderListMemberItems(nestedKeyValueName.second, valueTargetShape, nestedValueContainer, level + 1)
                    }
                }
                else -> {
                    if (level == 0) {
                        val memberNamespaceTraitGenerator = XMLNamespaceTraitGenerator.construct(member)
                        memberNamespaceTraitGenerator?.render(writer, nestedContainer)?.appendKey(xmlNamespaces)
                    }
                    renderFlattenedNestedMapKey(nestedContainer, resolvedCodingKeys, mapShape, nestedKeyValueName, level)
                    writer.write("var valueContainer = $nestedContainer.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedCodingKeys.second}\"))")
                    XMLNamespaceTraitGenerator.construct(mapShape.value)?.render(writer, "valueContainer")?.appendKey(xmlNamespaces)
                    writer.write("try valueContainer.encode(${nestedKeyValueName.second}, forKey: Key(\"\"))")
                }
            }
        }
    }

    private fun renderFlattenedNestedMapKey(
        nestedContainer: String,
        resolvedCodingKeys: Pair<XMLNameTraitGenerator, XMLNameTraitGenerator>,
        mapShape: MapShape,
        nestedKeyValueName: Pair<String, String>,
        level: Int
    ) {
        val nestedKeyContainer = "nestedKeyContainer$level"
        writer.write("var $nestedKeyContainer = $nestedContainer.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedCodingKeys.first}\"))")
        XMLNamespaceTraitGenerator.construct(mapShape.key)?.render(writer, nestedKeyContainer)?.appendKey(xmlNamespaces)
        writer.write("try $nestedKeyContainer.encode(${nestedKeyValueName.first}, forKey: Key(\"\"))")
    }

    private fun renderFlattenedNestedMapValue(
        nestedKeyValueName: Pair<String, String>,
        resolvedCodingKeys: Pair<XMLNameTraitGenerator, XMLNameTraitGenerator>,
        mapShape: MapShape,
        valueTargetShape: Shape,
        nestedContainer: String,
        level: Int,
        valueRenderer: (String) -> Unit
    ) {
        val isBoxed = ctx.symbolProvider.toSymbol(valueTargetShape).isBoxed()
        val nestedValueContainer = "nestedValueContainer$level"
        if (isBoxed && !(valueTargetShape is SetShape)) {
            writer.openBlock("if let ${nestedKeyValueName.second} = ${nestedKeyValueName.second} {", "}") {
                writer.write("var $nestedValueContainer = $nestedContainer.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedCodingKeys.second}\"))")
                XMLNamespaceTraitGenerator.construct(mapShape.value)?.render(writer, nestedValueContainer)?.appendKey(xmlNamespaces)
                valueRenderer(nestedValueContainer)
            }
        } else {
            // Todo: Write a unit test for this
            writer.write("var $nestedValueContainer = $nestedContainer.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedCodingKeys.second}\"))")
            XMLNamespaceTraitGenerator.construct(mapShape.value)?.render(writer, nestedValueContainer)?.appendKey(xmlNamespaces)
            valueRenderer(nestedValueContainer)
        }
    }

    fun renderTimestampMember(member: MemberShape, memberTarget: TimestampShape, containerName: String) {
        val symbol = ctx.symbolProvider.toSymbol(memberTarget)
        val memberName = ctx.symbolProvider.toMemberName(member)
        val resolvedMemberName = XMLNameTraitGenerator.construct(member, memberName)
        val format = determineTimestampFormat(member, defaultTimestampFormat)
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

    fun renderScalarMember(member: MemberShape, memberTarget: Shape, containerName: String) {
        val symbol = ctx.symbolProvider.toSymbol(memberTarget)
        val memberName = ctx.symbolProvider.toMemberName(member)
        val resolvedMemberName = XMLNameTraitGenerator.construct(member, memberName).toString()
        val isBoxed = symbol.isBoxed()
        if (isBoxed) {
            writer.openBlock("if let $memberName = $memberName {", "}") {
                val namespaceTraitGenerator = XMLNamespaceTraitGenerator.construct(member)
                val nestedContainerName = "${memberName}Container"
                renderItem(writer, namespaceTraitGenerator, nestedContainerName, containerName, memberName, resolvedMemberName)
            }
        } else {
            if (primitiveSymbols.contains(memberTarget.type)) {
                val defaultValue = getDefaultValueOfShapeType(memberTarget.type)
                writer.openBlock("if $memberName != $defaultValue {", "}") {
                    writer.write("try $containerName.encode($memberName, forKey: Key(\"$resolvedMemberName\"))")
                }
            } else {
                writer.write("try $containerName.encode($memberName, forKey: Key(\"$resolvedMemberName\"))")
            }
        }
    }

    private fun renderItem(writer: SwiftWriter, XMLNamespaceTraitGenerator: XMLNamespaceTraitGenerator?, nestedContainerName: String, containerName: String, memberName: String, resolvedMemberName: String) {
        XMLNamespaceTraitGenerator?.let {
            writer.write("var $nestedContainerName = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedMemberName}\"))")
            writer.write("try $nestedContainerName.encode($memberName, forKey: Key(\"\"))")
            it.render(writer, nestedContainerName)
            it.appendKey(xmlNamespaces)
        } ?: run {
            writer.write("try $containerName.encode($memberName, forKey: Key(\"${resolvedMemberName}\"))")
        }
    }
}
