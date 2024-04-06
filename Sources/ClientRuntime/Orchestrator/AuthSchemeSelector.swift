//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Component used by an Orchestrator to select an auth scheme to use for the operation.
public protocol SelectAuthScheme<AttributesType> {

    /// The type of the attributes the component requires.
    associatedtype AttributesType: HasAttributes

    /// Selects an auth scheme.
    /// - Parameter attributes: The attributes available.
    /// - Returns: The auth scheme to use, if available.
    func select(attributes: AttributesType) async throws -> SelectedAuthScheme?
}

/// Concrete SelectAuthScheme backed by a closure.
internal struct WrappedSelectAuthScheme<AttributesType: HasAttributes>: SelectAuthScheme {
    internal let closure: (AttributesType) async throws -> SelectedAuthScheme?

    public func select(attributes: AttributesType) async throws -> SelectedAuthScheme? {
        return try await closure(attributes)
    }
}
