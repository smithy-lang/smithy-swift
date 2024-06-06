/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import protocol SmithyChecksumsAPI.Checksum
import enum SmithyChecksumsAPI.ChecksumAlgorithm
import enum SmithyChecksumsAPI.HashResult
import struct Foundation.Data
import AwsCommonRuntimeKit

public enum HashError: Error {
    case invalidInput
    case hashingFailed(reason: String)
}

public enum UnknownChecksumError: Error {
    case notSupported(checksum: String)
}

extension ChecksumAlgorithm {

    static func from(string: String) -> (ChecksumAlgorithm)? {
        switch string.lowercased() {
        case "crc32": return .crc32
        case "crc32c": return .crc32c
        case "sha1": return .sha1
        case "sha256": return .sha256
        case "md5": return .md5 // md5 is not a valid flexible checksum algorithm
        default: return .unknown(string)
        }
    }

    static func fromList(_ stringArray: [String]) -> [ChecksumAlgorithm] {
        var hashFunctions = [ChecksumAlgorithm]()
        for string in stringArray {
            if let hashFunction = ChecksumAlgorithm.from(string: string) {
                hashFunctions.append(hashFunction)
            }
        }

        return hashFunctions
    }

    var isFlexibleChecksum: Bool {
        switch self {
        case .crc32, .crc32c, .sha256, .sha1:
            return true
        default:
            return false
        }
    }

    func createChecksum() throws -> any Checksum {
        switch self {
        case .crc32:
            return CRC32()
        case .crc32c:
            return CRC32C()
        case .sha1:
            return SHA1()
        case .sha256:
            return SHA256()
        case .md5:
           return MD5()
        case .unknown(let checksum):
            throw UnknownChecksumError.notSupported(checksum: checksum)
        }
    }
}

extension [ChecksumAlgorithm] {
    func getPriorityOrderValidationList() -> [ChecksumAlgorithm] {
        // Filter out .md5 if present and then sort the remaining hash functions
        return self.filter { $0 != .md5 }.sorted()
    }
}

extension UInt32 {
    func toBase64EncodedString() -> String {
        // Create a Data instance from the UInt32 value
        let value = self
        var bigEndianValue = value.bigEndian
        let data = Data(bytes: &bigEndianValue, count: MemoryLayout<UInt32>.size)

        // Base64 encode the data
        return data.base64EncodedString()
    }
}

extension HashResult {

    // Convert a HashResult to a hexadecimal String
    func toHexString() -> String {
        switch self {
        case .data(let data):
            return data.map { String(format: "%02x", $0) }.joined()
        case .integer(let integer):
            return String(format: "%08x", integer)
        }
    }

    // Convert a HashResult to a base64-encoded String
    func toBase64String() -> String {
        switch self {
        case .data(let data):
            return data.base64EncodedString()
        case .integer(let integer):
            return integer.toBase64EncodedString()
        }
    }
}
