/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.endpoints

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.rulesengine.language.EndpointRuleSet
import software.amazon.smithy.rulesengine.traits.EndpointBddTrait
import software.amazon.smithy.rulesengine.traits.EndpointRuleSetTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.swiftmodules.FoundationTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes
import software.amazon.smithy.swift.codegen.utils.SDKFileUtils
import java.util.Base64

/**
 * Generates a per/service endpoint resolver (internal to the generated SDK)
 */
class EndpointResolverGenerator(
    private val partitionDefinition: Symbol,
) {
    fun render(ctx: ProtocolGenerator.GenerationContext) {
        val ruleSetNode = ctx.service.getTrait<EndpointRuleSetTrait>()?.ruleSet
        val ruleSet = if (ruleSetNode != null) EndpointRuleSet.fromNode(ruleSetNode) else null
        val bytecode = bddBytecode(ctx)

        val filename = SDKFileUtils(ctx.settings).sourcesDirFilePath("Endpoints")
        ctx.delegator.useFileWriter(filename) {
            renderResolverProtocol(it, ctx.settings.visibility)
            it.write("")
            renderResolver(it, ruleSet, bytecode)
            renderStaticResolver(it)
            it.write("")
        }
    }

    /**
     * Compiles the endpointBdd trait to bytecode when the service has one, otherwise returns null.
     */
    private fun bddBytecode(ctx: ProtocolGenerator.GenerationContext): ByteArray? {
        val trait = ctx.service.getTrait<EndpointBddTrait>() ?: return null
        return BddBytecoder.compile(
            Node.printJson(trait.toNode()),
            ctx.settings.sdkId,
        )
    }

    private fun renderResolverProtocol(
        writer: SwiftWriter,
        visibility: String,
    ) {
        writer.openBlock("$visibility protocol \$N: \$N {", "}", EndpointTypes.EndpointResolver, SwiftTypes.Protocols.Sendable) {
            writer.write("func resolve(params: EndpointParams) throws -> \$N", SmithyHTTPAPITypes.Endpoint)
        }
    }

    private fun renderResolver(
        writer: SwiftWriter,
        endpointRuleSet: EndpointRuleSet?,
        bytecode: ByteArray?,
    ) {
        writer.write(
            "typealias DefaultEndpointResolver = \$N<EndpointParams>",
            ClientRuntimeTypes.Core.DefaultEndpointResolver,
        )
        writer.write("")
        writer.openBlock("extension DefaultEndpointResolver {", "}") {
            if (bytecode != null) {
                writer.write(
                    "private static let bytecode = \$N(base64Encoded: \$S)!",
                    FoundationTypes.Data,
                    Base64.getEncoder().encodeToString(bytecode),
                )
                writer.write("")
                writer.openBlock("init() throws {", "}") {
                    writer.write(
                        "try self.init(partitions: \$N, bytecode: Self.bytecode)",
                        partitionDefinition,
                    )
                }
            } else {
                endpointRuleSet?.let {
                    writer.write("private static let ruleSet = \$S", Node.printJson(it.toNode()))
                } ?: run {
                    writer.write("private static let ruleSet = \"{}\"")
                }
                writer.write("")
                writer.openBlock("init() throws {", "}") {
                    writer.write("try self.init(partitions: \$N, ruleSet: Self.ruleSet)", partitionDefinition)
                }
            }
        }
        writer.write("")
        writer.write("extension DefaultEndpointResolver: EndpointResolver where Params == EndpointParams {}")
    }

    private fun renderStaticResolver(writer: SwiftWriter) {
        writer.write("")
        writer.write(
            "typealias StaticEndpointResolver = \$N<EndpointParams>",
            ClientRuntimeTypes.Core.StaticEndpointResolver,
        )
        writer.write("")
        writer.write("extension StaticEndpointResolver: EndpointResolver {}")
    }
}
