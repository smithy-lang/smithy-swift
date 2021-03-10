/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration.serde.json

import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.defaultName
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeEncodeGeneratable

abstract class MemberShapeEncodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeEncodeGeneratable {

    fun renderListMember(
        member: MemberShape,
        memberTarget: Shape,
        containerName: String,
    ) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val listContainerName = "${memberName}Container"
        writer.openBlock("if let $memberName = $memberName {", "}") {
            writer.write("var $listContainerName = $containerName.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: .$memberName)")
            renderListMemberItems(memberName, listContainerName, memberTarget)
        }
    }

    private fun renderListMemberItems(
        collectionName: String,
        listContainerName: String,
        targetShape: Shape
    ) {
        val iteratorName = "${targetShape.defaultName().toLowerCase()}0"
        writer.openBlock("for $iteratorName in $collectionName {", "}") {
            when (targetShape) {
                is CollectionShape -> {
                    writer.write("try $listContainerName.encode($iteratorName, forKey: .member)")
                }
                is MapShape -> {
                    throw Exception("Maps Not supported yet")
                }
                else -> {
                    throw Exception("Other shapes not supported yet")
                }
            }
        }
    }
}
