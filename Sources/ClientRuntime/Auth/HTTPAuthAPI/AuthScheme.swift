//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol AuthScheme {
    var schemeId: String { get }
    var signer: any Signer { get }
    var idType: IdentityType { get }
}

extension AuthScheme {
    func identityResolver(config: IdentityResolverConfiguration) -> (any IdentityResolver)? {
        return config.getIdentityResolver(identityType: self.idType)
    }
}
