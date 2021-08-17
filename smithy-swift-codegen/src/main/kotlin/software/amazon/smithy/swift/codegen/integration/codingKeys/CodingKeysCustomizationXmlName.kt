/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.codingKeys

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.traits.XmlNameTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.xml.trait.XMLNameTraitGenerator
import software.amazon.smithy.swift.codegen.model.hasTrait

class CodingKeysCustomizationXmlName : CodingKeysCustomizable {
    override fun shouldHandleMember(member: MemberShape): Boolean {
        return member.hasTrait<XmlNameTrait>()
    }

    override fun handleMember(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, member: MemberShape) {
        val xmlName = XMLNameTraitGenerator.construct(member, member.memberName)
        val modifiedMemberName = ctx.symbolProvider.toMemberName(member)
        writer.write("case $modifiedMemberName = \"$xmlName\"")
    }
}
