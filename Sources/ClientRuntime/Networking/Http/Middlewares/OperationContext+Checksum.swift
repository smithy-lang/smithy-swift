//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum SmithyHTTPAPI.AttributeKeys
import struct SmithyAPI.AttributeKey
import class SmithyAPI.OperationContext

extension OperationContext {

    var checksum: ChecksumAlgorithm? {
        get {
            attributes.get(key: checksumKey)
        }
        set {
            attributes.set(key: checksumKey, value: newValue)
        }
    }
}

private let checksumKey = AttributeKey<ChecksumAlgorithm>(name: "checksumKey")
