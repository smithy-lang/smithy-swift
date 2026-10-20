//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Attributes
@_spi(ClientConfigDefaultIdentityResolver) import protocol SmithyIdentityAPI.ClientConfigDefaultIdentityResolver

/// A credential identity resolver that provides a fixed set of credentials
public struct StaticAWSCredentialIdentityResolver: AWSCredentialIdentityResolver {
    fileprivate let credentials: AWSCredentialIdentity

    @_spi(StaticAWSCredentialIdentityResolver)
    public init() {
        self.credentials = AWSCredentialIdentity(accessKey: "", secret: "")
    }

    /// Creates a credential identity resolver for a fixed set of credentials
    ///
    /// - Parameter credentials: The credentials that this provider will provide.
    ///
    /// - Returns: A credential identity resolver for a fixed set of credentials
    public init(_ credentials: AWSCredentialIdentity) {
        self.credentials = credentials
    }

    public func getIdentity(identityProperties: Attributes?) async throws -> AWSCredentialIdentity {
        return credentials
    }
}

@_spi(ClientConfigDefaultIdentityResolver)
extension StaticAWSCredentialIdentityResolver: ClientConfigDefaultIdentityResolver {

    public var isClientConfigDefault: Bool {
        self.credentials.accessKey.isEmpty && self.credentials.secret.isEmpty
    }
}
