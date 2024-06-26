//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyIdentityAPI.IdentityResolver
import protocol SmithyHTTPAuthAPI.IdentityResolverConfiguration
import struct Smithy.Attributes
import struct Smithy.AttributeKey

public struct DefaultIdentityResolverConfiguration: IdentityResolverConfiguration {
    let identityResolvers: Attributes

    public init(configuredIdResolvers: Attributes) {
        self.identityResolvers = configuredIdResolvers
    }

    public func getIdentityResolver(schemeID: String) throws -> (any IdentityResolver)? {
        return self.identityResolvers.get(key: AttributeKey<any IdentityResolver>(name: schemeID))
    }
}
