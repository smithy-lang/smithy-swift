//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval
import struct Smithy.AttributeKey
import class Smithy.Context
import class Smithy.ContextBuilder

public extension Context {
    var estimatedSkew: TimeInterval? {
        get { get(key: estimatedSkewKey) }
        set { set(key: estimatedSkewKey, value: newValue) }
    }

    var socketTimeout: TimeInterval? {
        get { get(key: socketTimeoutKey) }
        set { set(key: socketTimeoutKey, value: newValue) }
    }
}

public extension ContextBuilder {

    @discardableResult
    func withSocketTimeout(value newValue: TimeInterval) -> Self {
        attributes.set(key: socketTimeoutKey, value: newValue)
        return self
    }
}

private let estimatedSkewKey = AttributeKey<TimeInterval>(name: "estimatedSkewKey")
private let socketTimeoutKey = AttributeKey<TimeInterval>(name: "socketTimeoutKey")
