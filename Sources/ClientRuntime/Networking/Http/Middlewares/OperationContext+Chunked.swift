//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyAPI.AttributeKey
import class SmithyAPI.OperationContext

extension OperationContext {

    var isChunkedEligibleStream: Bool? {
        get {
            attributes.get(key: isChunkedEligibleStreamKey)
        }
        set {
            attributes.set(key: isChunkedEligibleStreamKey, value: newValue)
        }
    }
}

private let isChunkedEligibleStreamKey = AttributeKey<Bool>(name: "isChunkedEligibleStreamKey")
