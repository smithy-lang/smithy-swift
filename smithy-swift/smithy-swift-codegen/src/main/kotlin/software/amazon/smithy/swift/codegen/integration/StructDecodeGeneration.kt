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

import software.amazon.smithy.codegen.core.TopologicalIndex
import software.amazon.smithy.model.shapes.*
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.isRecursiveMember
import software.amazon.smithy.swift.codegen.recursiveSymbol

/**
 * Generates decode function for members bound to the payload.
 *
 * e.g.
 * ```
 *    public init decode(from decoder: Decoder) throws {
 *       let values = decoder.container(keyedBy: CodingKeys.self)
 *       booleanList = try values.decode([Bool].self, forKey: .booleanList)
 *       enumList = try values.decode([MyEnum.self], forKey: .enumList)
 *       integerList = try values.decode([Int].self, forKey: .integerList)
 *   }
 * ```
 */
class StructDecodeGeneration(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) {

    fun render() {
        var valuesContainer = "values"
        writer.openBlock("public init (from decoder: Decoder) throws {", "}") {
            writer.write("let \$L = try decoder.container(keyedBy: CodingKeys.self)", valuesContainer)
            members.forEach { member ->
                val target = ctx.model.expectShape(member.target)
                val memberName = member.memberName
                when (target) {
                    is CollectionShape -> {
                        //TODO
                        writer.write("$memberName = nil")
                    }
                    is MapShape -> {
                        //TODO
                        writer.write("$memberName = nil")
                    }
                    else -> {
                        var symbol = ctx.symbolProvider.toSymbol(target)
                        val topologicalIndex = TopologicalIndex.of(ctx.model)
                        if(member.isRecursiveMember(topologicalIndex)) {
                            symbol = symbol.recursiveSymbol()
                        }
                        writer.write("$memberName = try $valuesContainer.decodeIfPresent(\$L.self, forKey: .\$L)", symbol, memberName)
                    }
                }
            }
        }
    }


}