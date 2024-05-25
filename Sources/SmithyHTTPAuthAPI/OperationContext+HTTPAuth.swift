//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyAPI.Attributes
import struct SmithyAPI.AttributeKey
import class SmithyAPI.OperationContext
import class SmithyAPI.OperationContextBuilder

public extension OperationContext {

    func getAuthSchemes() -> Attributes? {
        return attributes.get(key: authSchemesKey)
    }

    func getSelectedAuthScheme() -> SelectedAuthScheme? {
        return attributes.get(key: selectedAuthSchemeKey)
    }

    func setSelectedAuthScheme(_ value: SelectedAuthScheme?) {
        attributes.set(key: selectedAuthSchemeKey, value: value)
    }

    func getAuthSchemeResolver() -> AuthSchemeResolver? {
        return attributes.get(key: authSchemeResolverKey)
    }
}

extension OperationContextBuilder {

    @discardableResult
    public func withAuthSchemeResolver(value: AuthSchemeResolver?) -> OperationContextBuilder {
        self.attributes.set(key: authSchemeResolverKey, value: value)
        return self
    }

    @discardableResult
    public func withAuthScheme(value: AuthScheme) -> OperationContextBuilder {
        var authSchemes: Attributes = self.attributes.get(key: authSchemesKey) ?? Attributes()
        authSchemes.set(key: AttributeKey<AuthScheme>(name: "\(value.schemeID)"), value: value)
        self.attributes.set(key: authSchemesKey, value: authSchemes)
        return self
    }

    @discardableResult
    public func withAuthSchemes(value: [AuthScheme]) -> OperationContextBuilder {
        for scheme in value {
            self.withAuthScheme(value: scheme)
        }
        return self
    }

    @discardableResult
    public func withSelectedAuthScheme(value: SelectedAuthScheme) -> OperationContextBuilder {
        self.attributes.set(key: selectedAuthSchemeKey, value: value)
        return self
    }
}

private let authSchemesKey = AttributeKey<Attributes>(name: "AuthSchemes")
private let authSchemeResolverKey = AttributeKey<AuthSchemeResolver>(name: "AuthSchemeResolver")
private let selectedAuthSchemeKey = AttributeKey<SelectedAuthScheme>(name: "SelectedAuthScheme")
