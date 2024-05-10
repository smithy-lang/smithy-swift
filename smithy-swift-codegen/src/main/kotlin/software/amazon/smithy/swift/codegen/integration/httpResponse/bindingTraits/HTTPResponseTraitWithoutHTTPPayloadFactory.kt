/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits

import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.HTTPResponseBindingRenderable

interface HTTPResponseTraitWithoutHTTPPayloadFactory {
    fun construct(
        ctx: ProtocolGenerator.GenerationContext,
        responseBindings: List<HttpBindingDescriptor>,
        outputShape: Shape,
        writer: SwiftWriter
    ): HTTPResponseBindingRenderable
}

class InitialResponse(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
) {

    private fun writeInitialResponseMembers(initialResponseMembers: Set<HttpBindingDescriptor>) {
        writer.apply {
            write("if let initialDataWithoutHttp = await messageDecoder.awaitInitialResponse() {")
            indent()
            write("let decoder = JSONDecoder()")
            write("do {")
            indent()
            write("let response = try decoder.decode([String: String].self, from: initialDataWithoutHttp)")
            initialResponseMembers.forEach { responseMember ->
                val responseMemberName = ctx.symbolProvider.toMemberName(responseMember.member)
                write("self.$responseMemberName = response[\"$responseMemberName\"]")
            }
            dedent()
            write("} catch {")
            indent()
            write("print(\"Error decoding JSON: \\(error)\")")
            initialResponseMembers.forEach { responseMember ->
                val responseMemberName = ctx.symbolProvider.toMemberName(responseMember.member)
                write("self.$responseMemberName = nil")
            }
            dedent()
            write("}")
            dedent()
            write("} else {")
            indent()
            initialResponseMembers.forEach { responseMember ->
                val responseMemberName = ctx.symbolProvider.toMemberName(responseMember.member)
                write("self.$responseMemberName = nil")
            }
            dedent()
            write("}")
        }
    }

    private fun isRPCService(ctx: ProtocolGenerator.GenerationContext): Boolean {
        return rpcBoundProtocols.contains(ctx.protocol.name)
    }

    /**
     * A set of RPC-bound Smithy protocols
     */
    private val rpcBoundProtocols = setOf(
        "awsJson1_0",
        "awsJson1_1",
        "awsQuery",
        "ec2Query",
    )
}
