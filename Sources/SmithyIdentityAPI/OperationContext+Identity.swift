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

extension OperationContext {

    public func getIdentityResolvers() -> Attributes? {
        return attributes.get(key: identityResolversKey)
    }
}

extension OperationContextBuilder {

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
