//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// IdentityInvalidator is an identity resolver that can mark an identity for refresh after a service rejects it.
public protocol IdentityInvalidator: IdentityResolver {
    func invalidate(_ identity: IdentityT) async
}
