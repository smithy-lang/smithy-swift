//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit

class SHA256 {
    private var sha256Checksum: Hash

    public init(sha256Checksum: Hash = Hash(algorithm: .SHA256)) {
        self.sha256Checksum = sha256Checksum
    }
}

extension SHA256: Checksum {
    static let checksumName = "sha256"
    static let digestLength: Int = 32 // bytes

    func copy() -> any Checksum {
        return SHA256(sha256Checksum: sha256Checksum)
    }

    func update(chunk: Data) throws {
        try sha256Checksum.update(data: chunk)
    }

    func reset() {
        sha256Checksum = Hash(algorithm: .SHA1)
    }

    func digest() throws -> HashResult {
        return try .data(sha256Checksum.finalize())
    }
}
