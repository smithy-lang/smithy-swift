//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyAPI.AttributeKey
import class SmithyAPI.OperationContext
import struct Foundation.TimeInterval

extension OperationContext {

    var estimatedSkew: TimeInterval? {
        get {
            attributes.get(key: estimatedSkewKey)
        }
        set {
            attributes.set(key: estimatedSkewKey, value: newValue)
        }
    }

    var socketTimeout: TimeInterval? {
        get {
            attributes.get(key: socketTimeoutKey)
        }
        set {
            attributes.set(key: socketTimeoutKey, value: newValue)
        }
    }
}

private let estimatedSkewKey = AttributeKey<TimeInterval>(name: "estimatedSkewKey")
private let socketTimeoutKey = AttributeKey<TimeInterval>(name: "socketTimeoutKey")
