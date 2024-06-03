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

    public func getIdentityResolvers() -> Attributes? {
        return attributes.get(key: identityResolversKey)
    }
}

extension ContextBuilder {

    @discardableResult
    public func removeIdentityResolvers() -> Self {
        attributes.remove(key: identityResolversKey)
        return self
    }

    @discardableResult
    public func withIdentityResolver<T: IdentityResolver>(value: T, schemeID: String) -> Self {
        var identityResolvers: Attributes = self.attributes.get(key: identityResolversKey) ?? Attributes()
        identityResolvers.set(key: AttributeKey<any IdentityResolver>(name: schemeID), value: value)
        self.attributes.set(key: identityResolversKey, value: identityResolvers)
        return self
    }
}

private let identityResolversKey = AttributeKey<Attributes>(name: "IdentityResolvers")
