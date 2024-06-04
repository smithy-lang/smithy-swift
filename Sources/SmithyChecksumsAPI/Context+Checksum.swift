//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import struct Smithy.AttributeKey

public extension Context {

    var checksum: ChecksumAlgorithm? {
        get { attributes.get(key: checksumKey) }
        set { attributes.set(key: checksumKey, value: newValue) }
    }
}

private let checksumKey = AttributeKey<ChecksumAlgorithm>(name: "checksumKey")
