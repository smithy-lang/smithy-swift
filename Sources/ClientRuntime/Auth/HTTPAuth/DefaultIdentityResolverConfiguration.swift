//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct DefaultIdentityResolverConfiguration: IdentityResolverConfiguration {
    let identityResolvers: Attributes

    public init(configuredIdResolvers: Attributes) {
        self.identityResolvers = configuredIdResolvers
    }

    func getIdentityResolver(schemeID: String) throws -> (any IdentityResolver)? {
        return self.identityResolvers.get(key: AttributeKey<any IdentityResolver>(name: schemeID))
    }
}
