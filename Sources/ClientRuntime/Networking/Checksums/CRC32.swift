//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit

class CRC32 {
    private var previousHash: UInt32

    public init(previousHash: UInt32 = UInt32()) {
        self.previousHash = previousHash
    }
}

extension CRC32: Checksum {
    static let checksumName = "crc32"
    static let digestLength: Int = 4 // bytes

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
