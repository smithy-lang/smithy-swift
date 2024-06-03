//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.AttributeKey
import class Smithy.Context
import class Smithy.ContextBuilder
import struct Foundation.TimeInterval

public extension Context {

    var estimatedSkew: TimeInterval? {
        get { attributes.get(key: estimatedSkewKey) }
        set { attributes.set(key: estimatedSkewKey, value: newValue) }
    }

    var socketTimeout: TimeInterval? {
        get { attributes.get(key: socketTimeoutKey) }
        set { attributes.set(key: socketTimeoutKey, value: newValue) }
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
