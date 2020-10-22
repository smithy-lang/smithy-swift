/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter

class UnionEncodeGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val members: List<MemberShape>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
): MemberShapeEncodeGenerator(ctx, writer, defaultTimestampFormat) {
    fun render() {
        val containerName = "container"
        writer.openBlock("public func encode(to encoder: Encoder) throws {", "}") {
            writer.write("var \$L = encoder.container(keyedBy: CodingKeys.self)", containerName)
            writer.openBlock("switch self {", "}") {
                val membersSortedByName: List<MemberShape> = members.sortedBy { it.memberName }
                membersSortedByName.forEach { member ->
                    val target = ctx.model.expectShape(member.target)
                    val memberName = ctx.symbolProvider.toMemberName(member)
                    writer.write("case let .\$L(\$L):", memberName, memberName)
                    writer.indent()
                    when (target) {
                        is CollectionShape -> {
                            writer.openBlock("if let \$L = \$L {", "}", memberName, memberName) {
                                renderEncodeListMember(target, memberName, containerName)
                            }
                        }
                        is MapShape -> {
                            writer.openBlock("if let \$L = \$L {", "}", memberName, memberName) {
                                renderEncodeMapMember(target, memberName, containerName)
                            }
                        }
                        else -> {
                            renderSimpleEncodeMember(target, member, containerName)
                        }
                    }
                    writer.dedent()
                }
                writer.write("case let .sdkUnknown(sdkUnknown):")
                writer.indent()
                writer.write("try container.encode(sdkUnknown, forKey: .sdkUnknown)")
                writer.dedent()
            }
        }
    }
}