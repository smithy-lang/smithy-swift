//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthSchemeMiddleware<Output: HttpResponseBinding, OutputError: HttpResponseErrorBinding>: Middleware {
    public let id: String = "AuthScheme"

    public init () {}

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
        // Get auth scheme resolver from context
        guard let resolver = context.getAuthSchemeResolver() else {
            throw ClientError.authError("No auth scheme resolver has been configured on the service.")
        }
        // Construct auth scheme resolver parameters
        let resolverParams = try resolver.constructParameters(context: context)
        let validAuthOptions = resolver.resolveAuthScheme(params: resolverParams)

        // Create IdentityResolverConfiguration
        guard let identityResolvers = context.getIdentityResolvers() else {
            throw ClientError.authError("No identity resolver has been configured on the service.")
        }
        let identityResolverConfig = DefaultIdentityResolverConfiguration(configuredIdResolvers: identityResolvers)

        // Get auth schemes configured on the service
        // If none is confugred, create empty Attributes object.
        let authSchemes = context.getAuthSchemes() ?? Attributes()
        
        // Variable for selected auth scheme
        var resolvedAuthScheme: SelectedAuthScheme?

        // For each auth option returned by auth scheme resolver:
        for option in validAuthOptions {
            // If current auth option is noAuth, set selectedAuthScheme with nil fields and break
            if (option.schemeID == "smithy.api#noAuth") {
                resolvedAuthScheme = SelectedAuthScheme(
                    schemeID: option.schemeID,
                    identity: nil,
                    signingProperties: nil,
                    signer: nil
                )
                break
            }
            // Otherwise,
            // 1) check if corresponding auth scheme for auth option is configured, then
            // 2) check if corresponding identity resolver for the auth scheme is configured
            if let authScheme = authSchemes.get(key: AttributeKey<AuthScheme>(name: "\(option.schemeID)")),
                let identityResolver = authScheme.identityResolver(config: identityResolverConfig) {
                // If both 1 & 2 are satisfied, resolve auth scheme
                do {
                    let signingProperties = authScheme.customizeSigningProperties(
                        signingProperties: option.signingProperties,
                        context: context
                    )
                    resolvedAuthScheme = await SelectedAuthScheme(
                        schemeID: option.schemeID,
                        // Resolve identity using the selected resolver from auth scheme
                        identity: try identityResolver.getIdentity(identityProperties: option.identityProperties),
                        signingProperties: signingProperties,
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
