//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyIdentityAPI.IdentityResolver

// This protocol exists for HTTP auth scheme resolution process.
// Concrete implementation of this protocol acts as the container for identity resolvers,
//    taken from the client config.
public protocol IdentityResolverConfiguration {
    func getIdentityResolver(schemeID: String) throws -> (any IdentityResolver)?
}
