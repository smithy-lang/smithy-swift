//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct DefaultIdentityResolverConfiguration: IdentityResolverConfiguration {
    let credentialsProvider: (any IdentityResolver)?

    public init(configuredIdResolvers: Attributes) {
        self.credentialsProvider = configuredIdResolvers.get(key: AttributeKeys.awsIdResolver) ?? nil
    }

    func getIdentityResolver(identityType: IdentityType) -> (any IdentityResolver)? {
        switch identityType {
        case .aws:
            return self.credentialsProvider
        }
    }
}
