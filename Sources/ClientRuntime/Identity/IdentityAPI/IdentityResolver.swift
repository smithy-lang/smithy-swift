//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// Base protocol for all identity provider types
public protocol IdentityResolver {
    associatedtype IdType: Identity

    func getIdentity(identityProperties: Attributes?) async throws -> IdType
}
