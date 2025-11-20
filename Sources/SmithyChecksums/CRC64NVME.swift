//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit
import struct Foundation.Data
import protocol SmithyChecksumsAPI.Checksum
import enum SmithyChecksumsAPI.HashResult

class CRC64NVME {
    let checksumName = "crc64nvme"
    let digestLength: Int = 8 // bytes

    private var previousHash: UInt64

    public init(previousHash: UInt64 = 0) {
        self.previousHash = previousHash
    }
}

extension CRC64NVME: Checksum {
    func copy() -> any Checksum {
        return CRC64NVME(previousHash: previousHash)
    }

    func update(chunk: Data) {
        self.previousHash = chunk.computeCRC64Nvme(previousCrc64Nvme: previousHash)
    }

    func reset() {
        self.previousHash = UInt64()
    }

    func digest() -> HashResult {
        return .integer64(previousHash)
    }
}
