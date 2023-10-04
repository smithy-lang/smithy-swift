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

    // Initializer for middleware will take in auth scheme resolver and parameters
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

        // For each auth option returned by auth scheme resolver:
        for option in validAuthOptions {
            // If current auth option is noAuth, set selectedAuthScheme with nil fields and break
            if (option.schemeId == "smithy.api#noAuth") {
                resolvedAuthScheme = SelectedAuthScheme(
                    schemeId: option.schemeId,
                    identity: nil,
                    signingProperties: nil,
                    signer: nil
                )
                break
            }
            // Otherwise,
            // 1) check if corresponding auth scheme for auth option is configured, then
            // 2) check if corresponding identity resolver for the auth scheme is configured
            if let authScheme = authSchemes.get(key: AttributeKey<AuthScheme>(name: "\(option.schemeId)")),
                let identityResolver = authScheme.identityResolver(config: identityResolverConfig) {
                // If both 1 & 2 are satisfied, resolve auth scheme
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
        
        // If no auth scheme could be resolved, throw an error
        guard let selectedAuthScheme = resolvedAuthScheme else {
            throw ClientError.authError("Could not resolve auth scheme for the operation call.")
        }
        
        // Set the selected auth scheme in context for subsequent middleware access, then pass to next middleware in chain
        return try await next.handle(context: context.toBuilder().withSelectedAuthScheme(value: selectedAuthScheme).build(), input: input)
    }
}
