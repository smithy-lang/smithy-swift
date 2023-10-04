//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthSchemeMiddleware<Output: HttpResponseBinding, OutputError: HttpResponseErrorBinding>: Middleware {
    public let id: String = "AuthScheme"
    let resolver: AuthSchemeResolver
    let resolverParams: AuthSchemeResolverParameters

    // Initializer for middleware will take in auth scheme resolver
    public init (resolver: AuthSchemeResolver, resolverParams: AuthSchemeResolverParameters) {
        self.resolver = resolver
        self.resolverParams = resolverParams
    }

    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<Output>
    public typealias Context = HttpContext

    public func handle<H>(context: HttpContext,
                          input: SdkHttpRequestBuilder,
                          next: H) async throws -> OperationOutput<Output>
    where H: Handler,
    Self.Context == H.Context,
    Self.MInput == H.Input,
    Self.MOutput == H.Output {

        let validAuthOptions = resolver.resolveAuthScheme(params: resolverParams)

        // Create IdentityResolverConfiguration
        let identityResolvers = context.getIdentityResolvers()
        let identityResolverConfig = DefaultIdentityResolverConfiguration(configuredIdResolvers: identityResolvers)

        // Get auth schemes configured on the service
        let authSchemes = context.getAuthSchemes()
        
        // Variable for selected auth scheme
        var resolvedAuthScheme: SelectedAuthScheme?

        for option in validAuthOptions {
            if (option.schemeId == "smithy.api#noAuth") {
                resolvedAuthScheme = SelectedAuthScheme(
                    schemeId: option.schemeId,
                    identity: nil,
                    signingProperties: nil,
                    signer: nil
                )
                break
            }
            if let authScheme = authSchemes.get(key: AttributeKey<AuthScheme>(name: "\(option.schemeId)")),
                let identityResolver = authScheme.identityResolver(config: identityResolverConfig) {
                do {
                    resolvedAuthScheme = await SelectedAuthScheme(
                        schemeId: option.schemeId,
                        // Resolve identity using the selected resolver from auth scheme
                        identity: try identityResolver.getIdentity(identityProperties: option.identityProperties),
                        signingProperties: option.signerProperties,
                        signer: authScheme.signer
                    )
                } catch {
                    // Could not fetch identity, move on to next auth option
                }
                break
            }
        }
        
        // If no auth scheme can be resolved, throw an error
        guard let selectedAuthScheme = resolvedAuthScheme else {
            throw ClientError.authError("Could not resolve auth scheme for the operation call.")
        }
        
        // Set the selected auth scheme in context for subsequent middleware access
        // Pass to next middleware in chain
        return try await next.handle(context: context.toBuilder().withSelectedAuthScheme(value: selectedAuthScheme).build(), input: input)
    }
}
