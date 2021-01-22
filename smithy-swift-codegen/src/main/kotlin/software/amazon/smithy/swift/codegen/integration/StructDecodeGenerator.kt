/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter

/**
 * Generates decode function for members bound to the payload.
 *
 * e.g.
 * ```
 public init (from decoder: Decoder) throws {
 let values = try decoder.container(keyedBy: CodingKeys.self)
 member1 = try values.decodeIfPresent(Int.self, forKey: .member1)
 let intListContainer = try values.decodeIfPresent([Int].self, forKey: .intList)
 var intListDecoded0 = [Int]()
 if let intListContainer = intListContainer {
 for integer0 in intListContainer {
 intListDecoded0.append(integer0)
 }
 }
 intList = intListDecoded0
 let intMapContainer = try values.decodeIfPresent([String:Int].self, forKey: .intMap)
 var intMapDecoded0 = [String:Int]()
 if let intMapContainer = intMapContainer {
 for (key0, integer0) in intMapContainer {
 intMapDecoded0[key0] = integer0
 }
 }
 intMap = intMapDecoded0
 }
 * ```
 */
class StructDecodeGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeDecodeGenerator(ctx, writer, defaultTimestampFormat) {
    fun render() {
        val containerName = "values"
        writer.openBlock("public init (from decoder: Decoder) throws {", "}") {
            if (members.isNotEmpty()) {
                writer.write("let \$L = try decoder.container(keyedBy: CodingKeys.self)", containerName)
                members.forEach { member ->
                    val target = ctx.model.expectShape(member.target)
                    val memberName = ctx.symbolProvider.toMemberName(member).removeSurrounding("`", "`")
                    when (target) {
                        is CollectionShape -> renderDecodeListMember(target, memberName, containerName, member)
                        is MapShape -> renderDecodeMapMember(target, memberName, containerName, member)
                        is TimestampShape -> renderDecodeForTimestamp(ctx, target, member, containerName)
                        else -> writeDecodeForPrimitive(target, member, containerName)
                    }
                }
            }
        }
    }
}
