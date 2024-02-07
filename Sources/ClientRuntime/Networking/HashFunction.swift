/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import AwsCommonRuntimeKit

public enum HashResult {
    case data(Data)
    case integer(UInt32)
}

public enum HashError: Error {
    case invalidInput
    case hashingFailed(reason: String)
}

public enum HashFunction {
    case crc32, crc32c, sha1, sha256, md5

    static func from(string: String) -> HashFunction? {
        switch string.lowercased() {
        case "crc32": return .crc32
        case "crc32c": return .crc32c
        case "sha1": return .sha1
        case "sha256": return .sha256
        case "md5": return .md5 // md5 is not a valid flexible checksum algorithm
        default: return nil
        }
    }
    
    static func fromList(_ stringArray: [String]) -> [HashFunction] {
        var hashFunctions = [HashFunction]()

        for string in stringArray {
            if let hashFunction = HashFunction.from(string: string) {
                hashFunctions.append(hashFunction)
            }
        }

        return hashFunctions
    }
    
    func toString() -> String {
        switch self {
        case .crc32: return "crc32"
        case .crc32c: return "crc32c"
        case .sha1: return "sha1"
        case .sha256: return "sha256"
        case .md5: return "md5"
        }
    }

    var isFlexibleChecksum: Bool {
        switch self {
        case .crc32, .crc32c, .sha256, .sha1:
            return true
        default:
            return false
        }
    }

    func computeHash(of data: Data) throws -> HashResult {
        switch self {
        case .crc32:
            return .integer(data.computeCRC32())
        case .crc32c:
            return .integer(data.computeCRC32C())
        case .sha1:
            do {
                let hashed = try data.computeSHA1()
                return .data(hashed)
            } catch {
                throw HashError.hashingFailed(reason: "Error computing SHA1: \(error)")
            }
        case .sha256:
            do {
                let hashed = try data.computeSHA256()
                return .data(hashed)
            } catch {
                throw HashError.hashingFailed(reason: "Error computing SHA256: \(error)")
            }
        case .md5:
            do {
                let hashed = try data.computeMD5()
                return .data(hashed)
            } catch {
                throw HashError.hashingFailed(reason: "Error computing MD5: \(error)")
            }
        }
    }
}

extension HashFunction: Comparable {
    /*
     * Priority-order for validating checksum = [ CRC32C, CRC32, SHA1, SHA256 ]
     * Order is determined by speed of the algorithm's implementation
     * MD5 is not supported by list ordering
     */
    public static func < (lhs: HashFunction, rhs: HashFunction) -> Bool {
        let order: [HashFunction] = [.crc32c, .crc32, .sha1, .sha256]

        let lhsIndex = order.firstIndex(of: lhs) ?? Int.max
        let rhsIndex = order.firstIndex(of: rhs) ?? Int.max

        return lhsIndex < rhsIndex
    }
}

extension [HashFunction] {
    func getPriorityOrderValidationList() -> [HashFunction] {
        // Filter out .md5 if present and then sort the remaining hash functions
        return self.filter { $0 != .md5 }.sorted()
    }
}

extension UInt32 {
    func toBase64EncodedString() -> String {
        // Create a Data instance from the UInt32 value
        var value = self
        var bigEndianValue = value.bigEndian
        var data = Data(bytes: &bigEndianValue, count: MemoryLayout<UInt32>.size)

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
