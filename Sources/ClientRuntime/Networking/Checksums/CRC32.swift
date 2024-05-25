//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import AwsCommonRuntimeKit

class CRC32 {
    let checksumName = "crc32"
    let digestLength: Int = 4 // bytes

    private var previousHash: UInt32

    public init(previousHash: UInt32 = 0) {
        self.previousHash = previousHash
    }
}

extension CRC32: Checksum {
    func copy() -> any Checksum {
        return CRC32(previousHash: previousHash)
    }

    func update(chunk: Data) {
        self.previousHash = chunk.computeCRC32(previousCrc32: previousHash)
    }

    func reset() {
        self.previousHash = UInt32()
    }

    func digest() -> HashResult {
        return .integer(previousHash)
    }
}
