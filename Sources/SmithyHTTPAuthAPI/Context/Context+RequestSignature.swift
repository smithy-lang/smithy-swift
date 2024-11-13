//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import class Smithy.ContextBuilder
import struct Smithy.AttributeKey

public extension Context {

    var requestSignature: String {
        get { get(key: requestSignatureKey) ?? "" }
        set { set(key: requestSignatureKey, value: newValue) }
    }
}

public extension ContextBuilder {

    @discardableResult
    func withRequestSignature(value: String) -> Self {
        self.attributes.set(key: requestSignatureKey, value: value)
        return self
    }
}

private let requestSignatureKey = AttributeKey<String>(name: "requestSignatureKey")
