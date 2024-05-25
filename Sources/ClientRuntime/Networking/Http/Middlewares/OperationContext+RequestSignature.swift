//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyAPI.AttributeKey
import class SmithyAPI.OperationContext
import class SmithyHTTPAPI.HttpResponse

extension OperationContext {

    var requestSignature: String? {
        get {
            attributes.get(key: requestSignatureKey)
        }
        set {
            attributes.set(key: requestSignatureKey, value: newValue)
        }
    }
}

private let requestSignatureKey = AttributeKey<String>(name: "requestSignatureKey")
