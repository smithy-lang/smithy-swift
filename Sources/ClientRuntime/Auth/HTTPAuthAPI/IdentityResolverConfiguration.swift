//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

protocol IdentityResolverConfiguration {
    func getIdentityResolver(identityKind: IdentityKind) -> (any IdentityResolver)?
}
