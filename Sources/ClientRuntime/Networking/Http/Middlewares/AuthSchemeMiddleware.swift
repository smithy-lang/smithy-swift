//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.ClientError
import struct Smithy.Attributes
import struct Smithy.AttributeKey
import class Smithy.Context
import class SmithyHTTPAPI.HTTPRequestBuilder
import struct SmithyHTTPAuthAPI.SelectedAuthScheme
import protocol SmithyHTTPAuthAPI.AuthScheme
import struct SmithyHTTPAuth.DefaultIdentityResolverConfiguration

public struct AuthSchemeMiddleware<OperationStackOutput> {
    public let id: String = "AuthSchemeMiddleware"

    public init() {}
}

extension AuthSchemeMiddleware: SelectAuthScheme {
    public func select(attributes: Context) async throws -> SelectedAuthScheme? {
        // Get auth scheme resolver from middleware context
        guard let resolver = attributes.getAuthSchemeResolver() else {
            throw ClientError.authError("No auth scheme resolver has been configured on the service.")
        }

        // Construct auth scheme resolver parameters
        let resolverParams = try resolver.constructParameters(context: attributes)
        // Retrieve valid auth options for the operation at hand
        let validAuthOptions = try resolver.resolveAuthScheme(params: resolverParams)

        // Create IdentityResolverConfiguration
        let identityResolvers = attributes.getIdentityResolvers()
        guard let identityResolvers, identityResolvers.size > 0 else {
            throw ClientError.authError("No identity resolver has been configured on the service.")
        }
        let identityResolverConfig = DefaultIdentityResolverConfiguration(configuredIdResolvers: identityResolvers)

        // Get auth schemes configured on the service
        // If none is confugred, create empty Attributes object
        let validAuthSchemes = attributes.getAuthSchemes() ?? Attributes()

        // Variable for selected auth scheme
        var selectedAuthScheme: SelectedAuthScheme?

        // Error message to throw if no auth scheme can be resolved
        var log: [String] = []

        // For each auth option returned by auth scheme resolver:
        for option in validAuthOptions {
            // If current auth option is noAuth, set selectedAuthScheme with nil fields and break
            if option.schemeID == "smithy.api#noAuth" {
                selectedAuthScheme = SelectedAuthScheme(
                    schemeID: option.schemeID,
                    identity: nil,
                    signingProperties: nil,
                    signer: nil
                )
                break
            }
            // Otherwise,
            // 1) check if corresponding auth scheme for current auth option is configured on the service, then
            // 2) check if corresponding identity resolver for the auth scheme is configured
            // If both 1 & 2 are satisfied, resolve auth scheme and save to selectedAuthScheme
            if let authScheme = validAuthSchemes.get(key: AttributeKey<AuthScheme>(name: "\(option.schemeID)")) {
                if let identityResolver = try authScheme.identityResolver(config: identityResolverConfig) {
                    // Hook for auth scheme to customize signing properties
                    let signingProperties = try authScheme.customizeSigningProperties(
                        signingProperties: option.signingProperties,
                        context: attributes
                    )
                    // Resolve identity using the resolver from auth scheme
                    var modifiedIdentityProperties = option.identityProperties
                    modifiedIdentityProperties.set(
                        key: IdentityPropertyKeys.clientConfigWrapper,
                        value: ClientConfigurationWrapper(clientConfig: attributes.clientConfig)
                    )
                    let identity = try await identityResolver.getIdentity(
                        identityProperties: modifiedIdentityProperties
                    )
                    // Save selected auth scheme
                    selectedAuthScheme = SelectedAuthScheme(
                        schemeID: option.schemeID,
                        identity: identity,
                        signingProperties: signingProperties,
                        signer: authScheme.signer
                    )
                    break
                } else {
                    log.append("Auth scheme \(option.schemeID) did not have an identity resolver configured.")
                }
            } else {
                log.append("Auth scheme \(option.schemeID) was not enabled for this request.")
            }
        }

        // If no auth scheme could be resolved, throw an error
        guard let selectedAuthScheme else {
            throw ClientError.authError(
                "Could not resolve auth scheme for the operation call. Log: \(log.joined(separator: ","))"
            )
        }

        // Set the selected auth scheme in context for subsequent middleware access
        attributes.setSelectedAuthScheme(selectedAuthScheme)

        return selectedAuthScheme
    }
}
