/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.codingKeys

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

interface CodingKeysCustomizable {
    fun shouldHandleMember(member: MemberShape): Boolean
    fun handleMember(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, member: MemberShape)
}
