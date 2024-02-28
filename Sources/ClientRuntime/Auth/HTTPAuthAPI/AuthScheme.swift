//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol AuthScheme {
    var schemeID: String { get }
    var signer: Signer { get }

    // Hook used by AuthSchemeMiddleware that allows signing properties customization, if needed by an auth scheme
    func customizeSigningProperties(signingProperties: Attributes, context: HttpContext) throws -> Attributes
}

extension AuthScheme {
    func identityResolver(config: IdentityResolverConfiguration) throws -> (any IdentityResolver)? {
        return try config.getIdentityResolver(schemeID: self.schemeID)
    }
}
