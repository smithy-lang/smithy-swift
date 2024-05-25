//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyAPI.Attributes
import class SmithyAPI.OperationContext
import protocol SmithyIdentityAPI.IdentityResolver
import protocol SmithyIdentityAPI.IdentityResolverConfiguration

public protocol AuthScheme {
    var schemeID: String { get }
    var signer: Signer { get }

    // Hook used by AuthSchemeMiddleware that allows signing properties customization, if needed by an auth scheme
    func customizeSigningProperties(signingProperties: Attributes, context: OperationContext) throws -> Attributes
}

public extension AuthScheme {

    func identityResolver(config: IdentityResolverConfiguration) throws -> (any IdentityResolver)? {
        return try config.getIdentityResolver(schemeID: self.schemeID)
    }
}
