//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import protocol SmithyIdentityAPI.IdentityResolver
import struct Smithy.Attributes

public protocol AuthScheme: Sendable {
    var schemeID: String { get }
    var signer: Signer { get }

    // Hook used by AuthSchemeMiddleware that allows signing properties customization, if needed by an auth scheme
    func customizeSigningProperties(signingProperties: Attributes, context: Context) throws -> Attributes
}

public extension AuthScheme {
    func identityResolver(config: IdentityResolverConfiguration) throws -> (any IdentityResolver)? {
        return try config.getIdentityResolver(schemeID: self.schemeID)
    }
}

public typealias AuthSchemes = [AuthScheme]
