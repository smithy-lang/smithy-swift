//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Attributes
import struct Smithy.AttributeKey
import class Smithy.Context
import class Smithy.ContextBuilder

extension Context {
    /// Gets the auth scheme preference list from the context.
    /// - Returns: An array of auth scheme IDs in priority order, or nil if not set.
    public func getAuthSchemePreference() -> [String]? {
        get(key: authSchemePreferenceKey)
    }
}

extension ContextBuilder {
    /// Removes the auth scheme preference from the context.
    /// - Returns: Self for method chaining.
    @discardableResult
    public func removeAuthSchemePreference() -> Self {
        attributes.remove(key: authSchemePreferenceKey)
        return self
    }

    /// Sets the auth scheme priority from a preference list of IDs.
    @discardableResult
    public func withAuthSchemePreference(value: [String]?) -> Self {
        if value?.isEmpty ?? true {
            // If value in empty array, remove the attributes
            attributes.remove(key: authSchemePreferenceKey)
        } else {
            attributes.set(key: authSchemePreferenceKey, value: value)
        }
        return self
    }
}

// Private attribute keys
private let authSchemePreferenceKey = AttributeKey<[String]>(name: "AuthSchemePreference")
