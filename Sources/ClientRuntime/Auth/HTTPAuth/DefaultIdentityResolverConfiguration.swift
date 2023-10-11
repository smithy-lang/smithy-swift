//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct DefaultIdentityResolverConfiguration: IdentityResolverConfiguration {
    let credentialsProvider: (any IdentityResolver)?

    public init(configuredIdResolvers: Attributes) {
        self.credentialsProvider = configuredIdResolvers.get(key: AttributeKeys.awsIdResolver) ?? nil
    }

    func getIdentityResolver(identityKind: IdentityKind) -> (any IdentityResolver)? {
        switch identityKind {
        case .aws:
            return self.credentialsProvider
        }
    }
}
