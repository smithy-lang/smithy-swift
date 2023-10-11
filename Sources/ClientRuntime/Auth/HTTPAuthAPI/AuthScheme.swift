//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol AuthScheme {
    var schemeID: String { get }
    var signer: Signer { get }
    var idKind: IdentityKind { get }
    
    // Hook used in AuthSchemeMiddleware to append additional signing properties needed for SigV4 auth scheme
    func customizeSigningProperties(signingProperties: Attributes, context: HttpContext) -> Attributes
}

extension AuthScheme {
    func identityResolver(config: IdentityResolverConfiguration) -> (any IdentityResolver)? {
        return config.getIdentityResolver(identityKind: self.idKind)
    }
}
