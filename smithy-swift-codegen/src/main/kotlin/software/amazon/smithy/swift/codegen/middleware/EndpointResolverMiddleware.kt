/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.middleware

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.Middleware
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.endpoints.EndpointTypes
import software.amazon.smithy.swift.codegen.integration.steps.OperationBuildStep
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes

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
        ENDPOINT_RESOLVER to EndpointTypes.EndpointResolver,
        ENDPOINT_PARAMS to EndpointTypes.EndpointParams,
        AUTH_SCHEME_RESOLVER to ClientRuntimeTypes.Core.EndpointsAuthSchemeResolver
    )

    override fun generateInit() {
        writer.openBlock(
            "public init($ENDPOINT_RESOLVER: \$N, $ENDPOINT_PARAMS: \$N, $AUTH_SCHEME_RESOLVER: \$N = \$N()) {",
            "}",
            EndpointTypes.EndpointResolver,
            EndpointTypes.EndpointParams,
            ClientRuntimeTypes.Core.EndpointsAuthSchemeResolver,
            ClientRuntimeTypes.Core.DefaultEndpointsAuthSchemeResolver
        ) {
            writer.write("self.\$L = \$L", ENDPOINT_RESOLVER, ENDPOINT_RESOLVER)
            writer.write("self.\$L = \$L", ENDPOINT_PARAMS, ENDPOINT_PARAMS)
            writer.write("self.\$L = \$L", AUTH_SCHEME_RESOLVER, AUTH_SCHEME_RESOLVER)
        }
    }

    override fun renderExtensions() {
        writer.addImport(SwiftDependency.SMITHY.target)
        writer.addImport(SwiftDependency.SMITHY_HTTP_API.target)
        writer.addImport(SwiftDependency.SMITHY_HTTP_AUTH_API.target)
        writer.write(
            """
            extension EndpointResolverMiddleware: ApplyEndpoint {
                public func apply(
                    request: SdkHttpRequest,
                    selectedAuthScheme: SelectedAuthScheme?,
                    attributes: Smithy.Context) async throws -> SdkHttpRequest
                {
                    let builder = request.toBuilder()
                    
                    let endpoint = try endpointResolver.resolve(params: endpointParams)
                    
                    var signingName: String? = nil
                    var signingAlgorithm: String? = nil
                    if let authSchemes = endpoint.authSchemes() {
                        let schemes = try authSchemes.map { try EndpointsAuthScheme(from: ${'$'}${'$'}0) }
                        let authScheme = try authSchemeResolver.resolve(authSchemes: schemes)
                        signingAlgorithm = authScheme.name
                        switch authScheme {
                        case .sigV4(let param):
                            signingName = param.signingName
                        case .sigV4A(let param):
                            signingName = param.signingName
                        case .none:
                            break
                        }
                    }
                    
                    let smithyEndpoint = SmithyEndpoint(endpoint: endpoint, signingName: signingName)
                    
                    var host = ""
                    if let hostOverride = attributes.host {
                        host = hostOverride
                    } else {
                        host = "\(attributes.hostPrefix ?? "")\(smithyEndpoint.endpoint.host)"
                    }
                    
                    if let protocolType = smithyEndpoint.endpoint.protocolType {
                        builder.withProtocol(protocolType)
                    }
                    
                    if let signingName = signingName {
                       attributes.signingName = signingName 
                       attributes.selectedAuthScheme = selectedAuthScheme?.getCopyWithUpdatedSigningProperty(key: SigningPropertyKeys.signingName, value: signingName)
                    }
                    
                    if let signingAlgorithm = signingAlgorithm {
                        attributes.signingAlgorithm = signingAlgorithm
                    }
                    
                    if let headers = endpoint.headers {
                        builder.withHeaders(headers)
                    }
                    
                    return builder.withMethod(attributes.method)
                        .withHost(host)
                        .withPort(smithyEndpoint.endpoint.port)
                        .withPath(smithyEndpoint.endpoint.path.appendingPathComponent(attributes.path))
                        .withHeader(name: "Host", value: host)
                        .build()
                }
            }
            """.trimIndent()
        )
    }

    override fun generateMiddlewareClosure() {
        writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
        writer.write(
            """
            let selectedAuthScheme = context.selectedAuthScheme
            let request = input.build()
            let updatedRequest = try await apply(request: request, selectedAuthScheme: selectedAuthScheme, attributes: context)
            """.trimIndent()
        )
    }

    override fun renderReturn() {
        writer.write("return try await next.handle(context: context, input: updatedRequest.toBuilder())")
    }
}
