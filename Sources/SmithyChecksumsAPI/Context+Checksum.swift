//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.AttributeKey
import class Smithy.Context

public extension Context {

    var checksum: ChecksumAlgorithm? {
        get { get(key: checksumKey) }
        set { set(key: checksumKey, value: newValue) }
    }

    var checksumString: String? { self.checksum?.toString() }
}

private let checksumKey = AttributeKey<ChecksumAlgorithm>(name: "checksumKey")
