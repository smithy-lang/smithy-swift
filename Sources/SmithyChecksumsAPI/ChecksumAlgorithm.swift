//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum ChecksumAlgorithm {
    case crc32, crc32c, sha1, sha256, md5, unknown(String)

    public func toString() -> String {
        switch self {
        case .crc32: return "crc32"
        case .crc32c: return "crc32c"
        case .sha1: return "sha1"
        case .sha256: return "sha256"
        case .md5: return "md5"
        case .unknown(let unknownChecksum): return "Error: Unable to compute unknown checksum \(unknownChecksum)!"
        }
    }
}

extension ChecksumAlgorithm: Comparable {
    /*
     * Priority-order for validating checksum = [ CRC32C, CRC32, SHA1, SHA256 ]
     * Order is determined by speed of the algorithm's implementation
     * MD5 is not supported by list ordering
     */
    public static func < (lhs: ChecksumAlgorithm, rhs: ChecksumAlgorithm) -> Bool {
        let order: [ChecksumAlgorithm] = [.crc32c, .crc32, .sha1, .sha256]

        let lhsIndex = order.firstIndex(of: lhs) ?? Int.max
        let rhsIndex = order.firstIndex(of: rhs) ?? Int.max

        return lhsIndex < rhsIndex
    }
}
