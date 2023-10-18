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
}

extension AuthScheme {
    func identityResolver(config: IdentityResolverConfiguration) -> (any IdentityResolver)? {
        return config.getIdentityResolver(identityKind: self.idKind)
    }
}
