/*
 *
 *  * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  *
 *  * Licensed under the Apache License, Version 2.0 (the "License").
 *  * You may not use this file except in compliance with the License.
 *  * A copy of the License is located at
 *  *
 *  *  http://aws.amazon.com/apache2.0
 *  *
 *  * or in the "license" file accompanying this file. This file is distributed
 *  * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 *  * express or implied. See the License for the specific language governing
 *  * permissions and limitations under the License.
 *
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.TopologicalIndex
import software.amazon.smithy.model.shapes.*
import software.amazon.smithy.model.traits.BoxTrait
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.*

/**
 * Generates encode function for members bound to the payload.
 *
 * e.g.
 * ```
 *    public func encode(to encoder: Encoder) throws {
 *       var container = encoder.container(keyedBy: CodingKeys.self)
 *       try container.encode(booleanList, forKey: .booleanList)
 *       try container.encode(enumList, forKey: .enumList)
 *       try container.encode(integerList, forKey: .integerList)
 *       var nestedStringListContainer = container.nestedUnkeyedContainer(forKey: .nestedStringList)
 *       if let nestedStringList = nestedStringList {
 *         for stringlist0 in nestedStringList {
 *            try nestedStringListContainer.encode(stringlist0)
 *          }
 *       }
 *       try container.encode(stringList, forKey: .stringList)
 *       try container.encode(stringSet, forKey: .stringSet)
 *       try container.encode(structureList, forKey: .structureList)
 *       var timestampListContainer = container.nestedUnkeyedContainer(forKey: .timestampList)
 *       if let timestampList = timestampList {
 *          for timestamp0 in timestampList {
 *              try timestampListContainer.encode(timestamp0.timeIntervalSince1970)
 *          }
*        }
 *   }
 * ```
 */
class StructEncodeGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
): MemberShapeEncodeGenerator(ctx, writer, defaultTimestampFormat) {
    fun render() {
        val containerName = "container"
        writer.openBlock("public func encode(to encoder: Encoder) throws {", "}") {
            writer.write("var \$L = encoder.container(keyedBy: CodingKeys.self)", containerName)
            val membersSortedByName: List<MemberShape> = members.sortedBy { it.memberName }
            membersSortedByName.forEach { member ->
                val target = ctx.model.expectShape(member.target)
                val memberName = ctx.symbolProvider.toMemberName(member)
                when (target) {
                    is CollectionShape -> {
                        writer.openBlock("if let $memberName = $memberName {", "}") {
                            renderEncodeListMember(target, memberName, containerName)
                        }
                    }
                    is MapShape -> {
                        writer.openBlock("if let $memberName = $memberName {", "}") {
                            renderEncodeMapMember(target, memberName, containerName)
                        }
                    }
                    else -> {
                        renderSimpleEncodeMember(target, member, containerName)
                    }
                }
            }
        }
    }
}
