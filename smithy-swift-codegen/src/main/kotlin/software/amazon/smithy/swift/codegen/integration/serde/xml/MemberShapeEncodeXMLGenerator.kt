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
                    throw Exception("Maps not supported yet")
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
        //Todo: look into consistency of this with maps
        val defaultMemberName = if (level == 0) memberName else "member"
        val resolvedMemberName = XMLNameTraitGenerator.construct(member, defaultMemberName)
        val nestedContainer = "${memberName}Container$level"

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
                    throw Exception("MapShape not supported yet")
                }
                is TimestampShape -> {
                    writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"$resolvedMemberName\"))")
                    val format = determineTimestampFormat(nestedMember, defaultTimestampFormat)
                    XMLNamespaceTraitGenerator.construct(member)?.render(writer, nestedContainer)?.appendKey(xmlNamespaces)
                    val encodeValue = "TimestampWrapper($nestedMemberTargetName, format: .$format), forKey: Key(\"\")"
                    writer.write("try $nestedContainer.encode($encodeValue)")
                }
                else -> {
                    writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"$resolvedMemberName\"))")
                    XMLNamespaceTraitGenerator.construct(member)?.render(writer, nestedContainer)?.appendKey(xmlNamespaces)
                    writer.write("try $nestedContainer.encode($nestedMemberTargetName, forKey: Key(\"\"))")
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

        val resolvedKeyName = XMLNameTraitGenerator.construct(mapShape.key, "key")
        val resolvedValueName = XMLNameTraitGenerator.construct(mapShape.value, "value")

        val nestedKeyValueName = Pair("${keyTargetShape.id.name.toLowerCase()}Key$level", "${valueTargetShape.id.name.toLowerCase()}Value$level")
        val nestedKeyValueKeyName = Pair(resolvedKeyName, resolvedValueName)
        writer.openBlock("for (${nestedKeyValueName.first}, ${nestedKeyValueName.second}) in $memberName {", "}") {
            when (valueTargetShape) {
                is MapShape -> {
                    renderWrappedMapMemberItem(nestedKeyValueName, nestedKeyValueKeyName, valueTargetShape, mapShape, containerName, level)
                }
                is CollectionShape -> {
                    throw Exception("nested collections not supported (yet)")
                }
                else -> {
                    val mapShapeKeyNamespaceTraitGenerator = XMLNamespaceTraitGenerator.construct(mapShape.key)
                    val mapShapeValueNamespaceTraitGenerator = XMLNamespaceTraitGenerator.construct(mapShape.value)

                    writer.write("var entry = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"entry\"))")

                    writer.write("var keyContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedKeyName}\"))")
                    mapShapeKeyNamespaceTraitGenerator?.render(writer, "keyContainer")?.appendKey(xmlNamespaces)
                    writer.write("try keyContainer.encode(${nestedKeyValueName.first}, forKey: Key(\"\"))")

                    writer.write("var valueContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key(\"${resolvedValueName}\"))")
                    mapShapeValueNamespaceTraitGenerator?.render(writer, "valueContainer")?.appendKey(xmlNamespaces)
                    writer.write("try valueContainer.encode(${nestedKeyValueName.second}, forKey: Key(\"\"))")
                }
            }
        }
    }

    private fun renderWrappedMapMemberItem(
        nestedKeyValueName: Pair<String, String>,
        nestedKeyValueTagName: Pair<XMLNameTraitGenerator, XMLNameTraitGenerator>,
        valueTargetShape: MapShape,
        mapShape: MapShape,
        containerName: String,
        level: Int
    ) {
        val keyName = nestedKeyValueName.first
        val valueName = nestedKeyValueName.second
        val keyTagName = nestedKeyValueTagName.first
        val valueTagName = nestedKeyValueTagName.second

        val nestedContainer = "nestedMapEntryContainer$level"
        writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"entry\"))")
        writer.openBlock("if let $valueName = $valueName {", "}") {
            val nestedKeyContainer = "nestedKeyContainer$level"
            writer.write("var ${nestedKeyContainer} = ${nestedContainer}.nestedContainer(keyedBy: Key.self, forKey: Key(\"${keyTagName}\"))")
            XMLNamespaceTraitGenerator.construct(mapShape.key)?.render(writer, nestedKeyContainer)?.appendKey(xmlNamespaces)
            writer.write("try ${nestedKeyContainer}.encode($keyName, forKey: Key(\"\"))")

            val nextContainer = "nestedMapEntryContainer${level + 1}"
            writer.write("var $nextContainer = $nestedContainer.nestedContainer(keyedBy: Key.self, forKey: Key(\"${valueTagName}\"))")
            XMLNamespaceTraitGenerator.construct(mapShape.value)?.render(writer, nextContainer)?.appendKey(xmlNamespaces)

            renderWrappedMapMemberItem(valueName, valueTargetShape, nextContainer, level + 1)
        }
    }

    private fun renderFlattenedMapMemberItem(memberName: String, member: MemberShape, mapShape: MapShape, containerName: String, level: Int = 0) {
        val keyTargetShape = ctx.model.expectShape(mapShape.key.target)
        val valueTargetShape = ctx.model.expectShape(mapShape.value.target)

        val resolvedMemberName = if (level != 0) "entry" else XMLNameTraitGenerator.construct(member, memberName)

        val resolvedKeyName = XMLNameTraitGenerator.construct(mapShape.key, "key")
        val resolvedValueName = XMLNameTraitGenerator.construct(mapShape.value, "value")
        val keyValueKeyName = Pair(resolvedKeyName, resolvedValueName)

        val nestedKeyValue = Pair("${keyTargetShape.id.name.toLowerCase()}Key$level", "${valueTargetShape.id.name.toLowerCase()}Value$level")
        val nestedContainer = "nestedContainer$level"

        writer.openBlock("for (${nestedKeyValue.first}, ${nestedKeyValue.second}) in $memberName {", "}") {
            when (valueTargetShape) {
                is MapShape -> {
                    writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"$resolvedMemberName\"))")
                    renderNestedFlattenedMapEntryKeyValue(nestedKeyValue, keyValueKeyName, mapShape.value, valueTargetShape, nestedContainer, level)
                }
                is CollectionShape -> {
                    throw Exception("nested collections not supported (yet)")
                }
                else -> {
                    //is any of htis even correct? seriously.. what?
                    val memberNamespaceTraitGenerator = XMLNamespaceTraitGenerator.construct(member)
                    val mapShapeKeyNamespaceTraitGenerator = XMLNamespaceTraitGenerator.construct(mapShape.key)
                    val mapShapeValueNamespaceTraitGenerator = XMLNamespaceTraitGenerator.construct(mapShape.value)

                    writer.write("var $nestedContainer = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"$resolvedMemberName\"))")
                    memberNamespaceTraitGenerator?.render(writer, nestedContainer)?.appendKey(xmlNamespaces)

                    writer.write("var keyContainer = $nestedContainer.nestedContainer(keyedBy: Key.self, forKey: Key(\"$resolvedKeyName\"))")
                    mapShapeKeyNamespaceTraitGenerator?.render(writer, "keyContainer")?.appendKey(xmlNamespaces)
                    writer.write("try keyContainer.encode(${nestedKeyValue.first}, forKey: Key(\"\"))")

                    writer.write("var valueContainer = $nestedContainer.nestedContainer(keyedBy: Key.self, forKey: Key(\"$resolvedValueName\"))")
                    mapShapeValueNamespaceTraitGenerator?.render(writer, "valueContainer")?.appendKey(xmlNamespaces)
                    writer.write("try valueContainer.encode(${nestedKeyValue.second}, forKey: Key(\"\"))")
                }
            }
        }
    }

    private fun renderNestedFlattenedMapEntryKeyValue(
        keyValueName: Pair<String, String>,
        keyValueKeyName: Pair<XMLNameTraitGenerator, XMLNameTraitGenerator>,
        memberShape: MemberShape,
        mapShape: MapShape,
        containerName: String,
        level: Int
    ) {
        val keyName = keyValueName.first
        val valueName = keyValueName.second
        writer.openBlock("if let $valueName = $valueName {", "}") {
            writer.write("try $containerName.encode($keyName, forKey: Key(\"${keyValueKeyName.first}\"))")
            val nextContainer = "nestedMapEntryContainer${level + 1}"
            writer.write("var $nextContainer = $containerName.nestedContainer(keyedBy: Key.self, forKey: Key(\"${keyValueKeyName.second}\"))")
            renderFlattenedMapMemberItem(valueName, memberShape, mapShape, nextContainer, level + 1)
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
