/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.codingKeys

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class DefaultCodingKeysGenerator(private val codingKeysCustomizations: CodingKeysCustomizable) : CodingKeysGenerator {
    override fun generateCodingKeysForMembers(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, members: List<MemberShape>) {
        val membersSortedByName: List<MemberShape> = members.sortedBy { it.memberName }
        if (membersSortedByName.isEmpty()) {
            return
        }

        writer.openBlock("enum CodingKeys: \$N, \$N {", "}", SwiftTypes.String, SwiftTypes.CodingKey) {
            for (member in membersSortedByName) {
                val originalMemberName = member.memberName
                val modifiedMemberName = ctx.symbolProvider.toMemberName(member)

                if (codingKeysCustomizations.shouldHandleMember(member)) {
                    codingKeysCustomizations.handleMember(ctx, writer, member)
                } else {
                    when {
                        originalMemberName == modifiedMemberName -> {
                            writer.write("case $modifiedMemberName")
                        }
                        else -> {
                            writer.write("case \$L = \$S", modifiedMemberName, originalMemberName)
                        }
                    }
                }
            }
        }
    }
}
