//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.AttributeKey
import class Smithy.Context
import class Smithy.ContextBuilder

public extension Context {
    var isChunkedEligibleStream: Bool? {
        get { get(key: isChunkedEligibleStreamKey) }
        set { set(key: isChunkedEligibleStreamKey, value: newValue) }
    }

    /// Flag controlling whether aws-chunked content encoding may be used for eligible
    /// streaming requests. When `false`, aws-chunked encoding is disabled even for
    /// eligible streams. Defaults to `true` when unset to preserve existing behavior.
    var enableAwsChunked: Bool {
        get { get(key: enableAwsChunkedKey) ?? true }
        set { set(key: enableAwsChunkedKey, value: newValue) }
    }
}

public extension ContextBuilder {
    @discardableResult
    func withEnableAwsChunked(value: Bool) -> Self {
        self.attributes.set(key: enableAwsChunkedKey, value: value)
        return self
    }
}

private let isChunkedEligibleStreamKey = AttributeKey<Bool>(name: "isChunkedEligibleStreamKey")
private let enableAwsChunkedKey = AttributeKey<Bool>(name: "enableAwsChunkedKey")
