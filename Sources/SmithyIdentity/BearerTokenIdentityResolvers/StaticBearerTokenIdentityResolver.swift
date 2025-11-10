//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Attributes
@_spi(ClientConfigDefaultIdentityResolver) import protocol SmithyIdentityAPI.ClientConfigDefaultIdentityResolver

/// The token identity resolver that returns a static token identity given to it at initialization.
public struct StaticBearerTokenIdentityResolver: BearerTokenIdentityResolver {
    fileprivate let token: BearerTokenIdentity

    @_spi(StaticBearerTokenIdentityResolver)
    public init() {
        self.token = BearerTokenIdentity(token: "")
    }

    public init(token: BearerTokenIdentity) {
        self.token = token
    }

    public func getIdentity(identityProperties: Smithy.Attributes?) async throws -> BearerTokenIdentity {
        return token
    }
}

@_spi(ClientConfigDefaultIdentityResolver)
extension StaticBearerTokenIdentityResolver: ClientConfigDefaultIdentityResolver {

    public var isClientConfigDefault: Bool {
        token.token.isEmpty
    }
}
