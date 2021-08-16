/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.codingKeys

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.traits.JsonNameTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.getTrait

class CodingKeysCustomizationJsonName : CodingKeysCustomizable {
    override fun shouldHandleMember(member: MemberShape): Boolean {
        return member.hasTrait(JsonNameTrait::class.java)
    }

    override fun handleMember(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, member: MemberShape) {
        val jsonName = member.getTrait<JsonNameTrait>()!!.value
        val modifiedMemberName = ctx.symbolProvider.toMemberName(member)
        writer.write("case $modifiedMemberName = \"$jsonName\"")
    }
}
