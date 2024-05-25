//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import AwsCommonRuntimeKit

class SHA256 {
    let checksumName = "sha256"
    let digestLength: Int = 32 // bytes

    private var sha256Checksum: Hash

    public init(sha256Checksum: Hash = Hash(algorithm: .SHA256)) {
        self.sha256Checksum = sha256Checksum
    }
}

extension SHA256: Checksum {
    func copy() -> any Checksum {
        return SHA256(sha256Checksum: self.sha256Checksum)
    }

    func update(chunk: Data) throws {
        try self.sha256Checksum.update(data: chunk)
    }

    func reset() {
        self.sha256Checksum = Hash(algorithm: .SHA1)
    }

    func digest() throws -> HashResult {
        return try .data(self.sha256Checksum.finalize())
    }
}
