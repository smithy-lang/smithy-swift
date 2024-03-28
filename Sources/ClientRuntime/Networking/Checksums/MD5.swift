//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit

class MD5 {
    private var md5Checksum: Hash

    public init(md5Checksum: Hash = Hash(algorithm: .MD5)) {
        self.md5Checksum = md5Checksum
    }
}

extension MD5: Checksum {
    static let checksumName = "md5"
    static let digestLength: Int = 16 // bytes

    func copy() -> any Checksum {
        return MD5(md5Checksum: md5Checksum)
    }

    func update(chunk: Data) throws {
        try md5Checksum.update(data: chunk)
    }

    func reset() {
        md5Checksum = Hash(algorithm: .MD5)
    }

    func digest() throws -> HashResult {
        return try .data(md5Checksum.finalize())
    }
}
