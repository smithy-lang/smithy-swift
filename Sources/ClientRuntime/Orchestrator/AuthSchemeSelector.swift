//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import struct SmithyHTTPAuthAPI.SelectedAuthScheme

/// Component used by an Orchestrator to select an auth scheme to use for the operation.
public protocol SelectAuthScheme {

    /// Selects an auth scheme.
    /// - Parameter attributes: The attributes available.
    /// - Returns: The auth scheme to use, if available.
    func select(attributes: Context) async throws -> SelectedAuthScheme?

    /// invalidate tells the identity resolver for `selected` that an attempt signed with its identity failed.
    func invalidate(selected: SelectedAuthScheme, error: any Error, attributes: Context) async
}

public extension SelectAuthScheme {

    func invalidate(selected: SelectedAuthScheme, error: any Error, attributes: Context) async {}
}

/// Concrete SelectAuthScheme backed by a closure.
internal struct WrappedSelectAuthScheme: SelectAuthScheme {
    internal let closure: (Context) async throws -> SelectedAuthScheme?

    public func select(attributes: Context) async throws -> SelectedAuthScheme? {
        return try await closure(attributes)
    }
}
