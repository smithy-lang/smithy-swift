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

    /// invalidate is called when a request signed with an identity from this resolver fails; the resolver decides which errors mean it was rejected.
    func invalidate(_ identity: IdentityT, error: any Error) async
}

public extension IdentityResolver {

    func invalidate(_ identity: IdentityT, error: any Error) async {}
}
