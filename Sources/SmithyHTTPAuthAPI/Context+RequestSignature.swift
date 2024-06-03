//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy

public extension Context {

    var requestSignature: String {
        get { attributes.get(key: requestSignatureKey) ?? "" }
        set { attributes.set(key: requestSignatureKey, value: newValue) }
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
