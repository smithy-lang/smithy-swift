//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit

class SHA1 {
    private var sha1Checksum: Hash

    public init(sha1Checksum: Hash = Hash(algorithm: .SHA1)) {
        self.sha1Checksum = sha1Checksum
    }
}

extension SHA1: Checksum {
    static let checksumName = "sha1"
    static let digestLength: Int = 20 // bytes

    func copy() -> any Checksum {
        return SHA1(sha1Checksum: sha1Checksum)
    }

    func update(chunk: Data) throws {
        try sha1Checksum.update(data: chunk)
    }

    func reset() {
        sha1Checksum = Hash(algorithm: .SHA1)
    }

    func digest() throws -> HashResult {
        return try .data(sha1Checksum.finalize())
    }
}
