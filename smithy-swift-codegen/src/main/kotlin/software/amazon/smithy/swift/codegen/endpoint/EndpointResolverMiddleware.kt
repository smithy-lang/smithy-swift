/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.endpoint

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.Middleware
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.steps.OperationBuildStep

const val ENDPOINT_RESOLVER = "endpointResolver"
const val AUTH_SCHEME_RESOLVER = "authSchemeResolver"
const val ENDPOINT_PARAMS = "endpointParams"

/**
 * Generates endpoint middleware for the service.
 */
open class EndpointResolverMiddleware(
    private val writer: SwiftWriter,
    inputSymbol: Symbol,
    outputSymbol: Symbol,
    outputErrorSymbol: Symbol
) : Middleware(writer, inputSymbol, OperationBuildStep(outputSymbol, outputErrorSymbol)) {

    override val id: String = "EndpointResolverMiddleware"

    override val typeName = "EndpointResolverMiddleware<$outputSymbol>"

    override val properties: MutableMap<String, Symbol> = mutableMapOf(
        ENDPOINT_RESOLVER to EndpointSymbols.EndpointResolver,
        ENDPOINT_PARAMS to EndpointSymbols.EndpointParams,
        AUTH_SCHEME_RESOLVER to ClientRuntimeTypes.Core.AuthSchemeResolver
    )

    override fun generateInit() {
        writer.openBlock(
            "public init($ENDPOINT_RESOLVER: \$N, $ENDPOINT_PARAMS: \$N, $AUTH_SCHEME_RESOLVER: \$N = \$N()) {",
            "}",
            EndpointSymbols.EndpointResolver,
            EndpointSymbols.EndpointParams,
            ClientRuntimeTypes.Core.AuthSchemeResolver,
            ClientRuntimeTypes.Core.DefaultAuthSchemeResolver
        ) {
            writer.write("self.\$L = \$L", ENDPOINT_RESOLVER, ENDPOINT_RESOLVER)
            writer.write("self.\$L = \$L", ENDPOINT_PARAMS, ENDPOINT_PARAMS)
            writer.write("self.\$L = \$L", AUTH_SCHEME_RESOLVER, AUTH_SCHEME_RESOLVER)
        }
    }

    override fun generateMiddlewareClosure() {
        writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
        writer.write("let endpoint = try endpointResolver.resolve(params: endpointParams)")
            .write("")

        writer.write("var signingName: String? = nil")
        writer.write("var signingAlgorithm: String? = nil")
        writer.openBlock("if let authSchemes = endpoint.authSchemes() {", "}") {
            writer.write("let schemes = try authSchemes.map { try EndpointAuthScheme(from: \$$0) }")
            writer.write("let authScheme = try authSchemeResolver.resolve(authSchemes: schemes)")
            writer.write("signingAlgorithm = authScheme.name")
            writer.write("switch authScheme {")
            writer.write("case .sigV4(let param):")
            writer.indent()
            writer.write("signingName = param.signingName")
            writer.dedent()
            writer.write("case .sigV4A(let param):")
            writer.indent()
            writer.write("signingName = param.signingName")
            writer.dedent()
            writer.write("case .none:")
            writer.indent()
            writer.write("break")
            writer.dedent()
            writer.write("}")
        }
        writer.write("")
        writer.write("let smithyEndpoint = SmithyEndpoint(endpoint: endpoint, signingName: signingName)")
            .write("")

        writer.write("""var host = """"")
            .openBlock("if let hostOverride = context.getHost() {", "} else {") {
                writer.write("host = hostOverride")
            }
            .indent()
            .write("""host = "\(context.getHostPrefix() ?? "")\(smithyEndpoint.endpoint.host)"""")
            .dedent()
            .write("}")

        writer.write("")
        writer.openBlock("if let protocolType = smithyEndpoint.endpoint.protocolType {", "}") {
            writer.write("input.withProtocol(protocolType)")
        }.write("")

        writer.openBlock("if let signingName = signingName {", "}") {
            writer.write("context.attributes.set(key: AttributeKeys.signingName, value: signingName)")
            writer.write("context.attributes.set(key: AttributeKeys.selectedAuthScheme, value: context.getSelectedAuthScheme()?.getCopyWithUpdatedSigningProperty(key: AttributeKeys.signingName, value: signingName))")
        }
        writer.openBlock("if let signingAlgorithm = signingAlgorithm {", "}") {
            writer.write("context.attributes.set(key: AttributeKeys.signingAlgorithm, value: AWSSigningAlgorithm(rawValue: signingAlgorithm))")
        }.write("")

        writer.openBlock("if let headers = endpoint.headers {", "}") {
            writer.write("input.withHeaders(headers)")
        }.write("")

        writer.write("input.withMethod(context.getMethod())")
            .indent()
            .write(".withHost(host)")
            .write(".withPort(smithyEndpoint.endpoint.port)")
            .write(".withPath(smithyEndpoint.endpoint.path.appendingPathComponent(context.getPath()))")
            .write(""".withHeader(name: "Host", value: host)""")
            .dedent()
            .write("")
    }

    override fun renderReturn() {
        writer.write("return try await next.handle(context: context, input: input)")
    }
}
