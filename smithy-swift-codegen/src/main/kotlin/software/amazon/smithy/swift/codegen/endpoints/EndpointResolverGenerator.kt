/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.endpoints

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.rulesengine.language.EndpointRuleSet
import software.amazon.smithy.rulesengine.traits.EndpointRuleSetTrait
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.Dependency
import software.amazon.smithy.swift.codegen.MiddlewareGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.middleware.EndpointResolverMiddleware
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAPITypes
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase

/**
 * Generates a per/service endpoint resolver (internal to the generated SDK)
 */
class EndpointResolverGenerator(
    private val partitionDefinition: Symbol,
    private val dependency: Dependency,
    private val endpointResolverMiddleware: (
        writer: SwiftWriter,
        inputSymbol: Symbol,
        outputSymbol: Symbol,
        outputErrorSymbol: Symbol
    ) -> EndpointResolverMiddleware
) {
    fun render(ctx: ProtocolGenerator.GenerationContext) {
        val rootNamespace = ctx.settings.moduleName

        val ruleSetNode = ctx.service.getTrait<EndpointRuleSetTrait>()?.ruleSet
        val ruleSet = if (ruleSetNode != null) EndpointRuleSet.fromNode(ruleSetNode) else null

        ctx.delegator.useFileWriter("./$rootNamespace/EndpointResolver.swift") {
            it.addImport(dependency.target)
            val endpointParamsGenerator = EndpointParamsGenerator(ruleSet)
            endpointParamsGenerator.render(it, ctx)
        }

        ctx.delegator.useFileWriter("./$rootNamespace/EndpointResolver.swift") {
            renderResolverProtocol(it)
            it.write("")
            renderResolver(it, ruleSet)
            val inputSymbol = Symbol.builder().name("SdkHttpRequestBuilder").build()
            val outputSymbol = Symbol.builder().name("OperationStackOutput").build()
            val outputErrorSymbol = Symbol.builder().name("OperationStackError").build()
            it.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            it.addImport(SwiftDependency.SMITHY_HTTP_API.target)
            it.write("")
            MiddlewareGenerator(it, endpointResolverMiddleware(it, inputSymbol, outputSymbol, outputErrorSymbol))
                .generate()
        }
    }

    private fun renderResolverProtocol(writer: SwiftWriter) {
        writer.openBlock("public protocol \$L {", "}", EndpointTypes.EndpointResolver) {
            writer.write("func resolve(params: EndpointParams) throws -> \$L", SmithyHTTPAPITypes.Endpoint)
        }
    }

    private fun renderResolver(writer: SwiftWriter, endpointRules: EndpointRuleSet?) {
        writer.openBlock("public struct \$L: \$L  {", "}", EndpointTypes.DefaultEndpointResolver, EndpointTypes.EndpointResolver) {
            writer.write("")
            endpointRules?.let {
                writer.write("private let engine: \$L", ClientRuntimeTypes.Core.EndpointsRuleEngine)
                writer.write("private let ruleSet = \$S", Node.printJson(endpointRules.toNode()))
            }
            writer.write("")
            writer.openBlock("public init() throws {", "}") {
                endpointRules?.let {
                    writer.write("engine = try \$L(partitions: \$L, ruleSet: ruleSet)", ClientRuntimeTypes.Core.EndpointsRuleEngine, partitionDefinition)
                }
            }
            writer.write("")
            writer.openBlock(
                "public func resolve(params: EndpointParams) throws -> \$L {", "}", SmithyHTTPAPITypes.Endpoint
            ) {
                endpointRules?.let {
                    writer.write("let context = try \$L()", ClientRuntimeTypes.Core.EndpointsRequestContext)
                    endpointRules.parameters?.toList()?.sortedBy { it.name.toString() }?.let { sortedParameters ->
                        sortedParameters.forEach { param ->
                            val memberName = param.name.toString().toLowerCamelCase()
                            val paramName = param.name.toString()
                            writer.write("try context.add(name: \$S, value: params.\$L)", paramName, memberName)
                        }
                        writer.write("")
                    }
                    writer.openBlock("guard let crtResolvedEndpoint = try engine.resolve(context: context) else {", "}") {
                        writer.write("throw EndpointError.unresolved(\"Failed to resolved endpoint\")")
                    }.write("")

                    writer.openBlock("if crtResolvedEndpoint.getType() == .error {", "}") {
                        writer.write("let error = crtResolvedEndpoint.getError()")
                        writer.write("throw EndpointError.unresolved(error)")
                    }.write("")

                    writer.openBlock("guard let url = crtResolvedEndpoint.getURL() else {", "}") {
                        writer.write("assertionFailure(\"This must be a bug in either CRT or the rule engine, if the endpoint is not an error, it must have a url\")")
                        writer.write("throw EndpointError.unresolved(\"Failed to resolved endpoint\")")
                    }.write("")

                    writer.write("let headers = crtResolvedEndpoint.getHeaders() ?? [:]")
                    writer.write("let properties = crtResolvedEndpoint.getProperties() ?? [:]")
                    writer.write("return try Endpoint(urlString: url, headers: Headers(headers), properties: properties)")
                } ?: run {
                    writer.write("fatalError(\"EndpointResolver not implemented\")")
                }
            }
        }
    }
}
