//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Attributes

/// A credential identity resolver that provides a fixed set of credentials
public struct StaticAWSCredentialIdentityResolver: AWSCredentialIdentityResolver {
    private let credentials: AWSCredentialIdentity

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
