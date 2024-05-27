//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyChecksumsAPI.Checksum
import enum SmithyChecksumsAPI.HashResult
import struct Foundation.Data
import AwsCommonRuntimeKit

class SHA1 {
    let checksumName = "sha1"
    let digestLength: Int = 20 // bytes

    private var sha1Checksum: Hash

    public init(sha1Checksum: Hash = Hash(algorithm: .SHA1)) {
        self.sha1Checksum = sha1Checksum
    }
}

extension SHA1: Checksum {
    func copy() -> any Checksum {
        return SHA1(sha1Checksum: self.sha1Checksum)
    }

    func update(chunk: Data) throws {
        try self.sha1Checksum.update(data: chunk)
    }

    func reset() {
        self.sha1Checksum = Hash(algorithm: .SHA1)
    }

    func digest() throws -> HashResult {
        return try .data(self.sha1Checksum.finalize())
    }
}
