//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Attributes

// Base protocol for all identity provider types
public protocol IdentityResolver: Sendable {
    associatedtype IdentityT: Identity

    func getIdentity(identityProperties: Attributes?) async throws -> IdentityT
}
