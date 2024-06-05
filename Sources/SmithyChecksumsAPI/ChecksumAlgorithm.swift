//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum ChecksumAlgorithm {
    case crc32, crc32c, sha1, sha256, md5

    func toString() -> String {
        switch self {
        case .crc32: return "crc32"
        case .crc32c: return "crc32c"
        case .sha1: return "sha1"
        case .sha256: return "sha256"
        case .md5: return "md5"
        }
    }
}
