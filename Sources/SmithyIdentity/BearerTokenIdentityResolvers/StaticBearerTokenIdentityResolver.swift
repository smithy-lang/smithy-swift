//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Attributes

/// The token identity resolver that returns a static token identity given to it at initialization.
public struct StaticBearerTokenIdentityResolver: BearerTokenIdentityResolver {
    private let token: BearerTokenIdentity

    public init(token: BearerTokenIdentity) {
        self.token = token
    }

    public func getIdentity(identityProperties: Smithy.Attributes?) async throws -> BearerTokenIdentity {
        return token
    }
}
