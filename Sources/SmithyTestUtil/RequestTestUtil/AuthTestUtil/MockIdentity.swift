//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

public struct MockIdentity: Identity {
    public init() {}
    public var expiration: ClientRuntime.Date? = nil
}

public struct MockIdentityResolver: IdentityResolver {
    public typealias IdentityT = MockIdentity
    public init() {}
    public func getIdentity(identityProperties: ClientRuntime.Attributes?) async throws -> MockIdentity {
        return MockIdentity()
    }
}
