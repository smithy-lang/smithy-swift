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

public extension Context {

    func getAuthSchemes() -> Attributes? {
        return attributes.get(key: authSchemesKey)
    }

    var selectedAuthScheme: SelectedAuthScheme? {
        get { attributes.get(key: selectedAuthSchemeKey) }
        set { attributes.set(key: selectedAuthSchemeKey, value: newValue) }
    }

    func setSelectedAuthScheme(_ value: SelectedAuthScheme?) {
        attributes.set(key: selectedAuthSchemeKey, value: value)
    }

    func getAuthSchemeResolver() -> AuthSchemeResolver? {
        return attributes.get(key: authSchemeResolverKey)
    }

    var signingAlgorithm: SigningAlgorithm? {
        get { attributes.get(key: signingAlgorithmKey) }
        set { attributes.set(key: signingAlgorithmKey, value: newValue) }
    }
}

extension ContextBuilder {

    @discardableResult
    public func withAuthSchemeResolver(value: AuthSchemeResolver?) -> ContextBuilder {
        self.attributes.set(key: authSchemeResolverKey, value: value)
        return self
    }

    @discardableResult
    public func withAuthScheme(value: AuthScheme) -> ContextBuilder {
        var authSchemes: Attributes = self.attributes.get(key: authSchemesKey) ?? Attributes()
        authSchemes.set(key: AttributeKey<AuthScheme>(name: "\(value.schemeID)"), value: value)
        self.attributes.set(key: authSchemesKey, value: authSchemes)
        return self
    }

    @discardableResult
    public func withAuthSchemes(value: [AuthScheme]) -> ContextBuilder {
        for scheme in value {
            self.withAuthScheme(value: scheme)
        }
        return self
    }

    @discardableResult
    public func withSelectedAuthScheme(value: SelectedAuthScheme) -> ContextBuilder {
        self.attributes.set(key: selectedAuthSchemeKey, value: value)
        return self
    }

    @discardableResult
    public func withSigningAlgorithm(value: SigningAlgorithm) -> Self {
        self.attributes.set(key: signingAlgorithmKey, value: value)
        return self
    }
}

private let authSchemesKey = AttributeKey<Attributes>(name: "AuthSchemes")
private let authSchemeResolverKey = AttributeKey<AuthSchemeResolver>(name: "AuthSchemeResolver")
private let selectedAuthSchemeKey = AttributeKey<SelectedAuthScheme>(name: "SelectedAuthScheme")
private let signingAlgorithmKey = AttributeKey<SigningAlgorithm>(name: "SigningAlgorithmKey")
