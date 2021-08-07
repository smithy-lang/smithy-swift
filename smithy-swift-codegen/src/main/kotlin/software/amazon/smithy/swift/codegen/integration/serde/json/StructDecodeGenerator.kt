/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.json

import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.toMemberNames

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
    override fun render() {
        val containerName = "containerValues"
        writer.openBlock("public init (from decoder: \$N) throws {", "}", SwiftTypes.Decoder) {
            if (members.isNotEmpty()) {
                writer.write("let \$L = try decoder.container(keyedBy: CodingKeys.self)", containerName)
                members.forEach { member ->
                    val target = ctx.model.expectShape(member.target)
                    val memberNames = ctx.symbolProvider.toMemberNames(member)
                    when (target) {
                        is CollectionShape -> renderDecodeListMember(target, memberNames.second, containerName, member)
                        is MapShape -> renderDecodeMapMember(target, memberNames.second, containerName, member)
                        is TimestampShape -> renderDecodeForTimestamp(ctx, target, member, containerName)
                        else -> writeDecodeForPrimitive(target, member, containerName)
                    }
                }
            }
        }
    }
}
