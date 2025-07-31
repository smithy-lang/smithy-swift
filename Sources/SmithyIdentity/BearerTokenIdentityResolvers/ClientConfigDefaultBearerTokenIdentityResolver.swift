//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Attributes

/// A bearer token resolver used to signify that this resolver is a default resolver created because the client config was not passed a custom resolver at creation.
///
/// Performs no resolution of its own, instead it returns the bearer token resolved by its inner resolver.
public struct ClientConfigDefaultBearerTokenIdentityResolver {
    private let innerResolver: any BearerTokenIdentityResolver

    public init(_ innerResolver: any BearerTokenIdentityResolver) {
        self.innerResolver = innerResolver
    }
}

extension ClientConfigDefaultBearerTokenIdentityResolver: BearerTokenIdentityResolver {

    public func getIdentity(identityProperties: Attributes?) async throws -> BearerTokenIdentity {
        try await innerResolver.getIdentity(identityProperties: identityProperties)
    }
}
