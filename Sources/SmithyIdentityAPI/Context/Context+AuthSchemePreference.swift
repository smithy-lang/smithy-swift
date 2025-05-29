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
    
    /// Sets the auth scheme priority from a preference string.
    /// - Parameter preference: A comma-separated string of auth scheme IDs.
    /// - Returns: Self for method chaining.
    @discardableResult
    public func withAuthSchemePreference(value: String?) -> Self {
        guard let value = value, !value.isEmpty else {
            // Remove the attributes if value is nil or empty
            attributes.remove(key: authSchemePreferenceKey)
            return self
        }
        
        let normalizedSchemes = normalizeSchemes(value)
        if normalizedSchemes.isEmpty {
            // If normalization results in empty array, remove the attributes
            attributes.remove(key: authSchemePreferenceKey)
        } else {
            attributes.set(key: authSchemePreferenceKey, value: normalizedSchemes)
        }
        return self
    }
}

func normalizeSchemes(_ input: String) -> [String] {
    return input
        .split(separator: ",")
        .map { $0.replacingOccurrences(of: "[ \\t]+", with: "", options: .regularExpression) }
        .filter { !$0.isEmpty }
}

// Private attribute keys
private let authSchemePreferenceKey = AttributeKey<[String]>(name: "AuthSchemePreference")