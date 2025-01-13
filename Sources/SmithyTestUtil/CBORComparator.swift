//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit
import Foundation
@_spi(SmithyReadWrite) import SmithyCBOR

public struct CBORComparator {
    /// Returns true if the logical CBOR values represented by the `Reader` instances are equal.
    /// - Parameters:
    ///   - dataA: The first CBOR data object to compare.
    ///   - dataB: The second CBOR data object to compare.
    /// - Returns: Returns true if the CBOR documents are equal.
    public static func cborData(_ dataA: Data, isEqualTo dataB: Data) throws -> Bool {
        let readerA = try Reader.from(data: dataA)
        let readerB = try Reader.from(data: dataB)
        return compareReaders(readerA, readerB)
    }

    private static func compareReaders(_ readerA: Reader, _ readerB: Reader) -> Bool {
        if !anyCBORValuesAreEqual(readerA.cborValue, readerB.cborValue) {
            return false
        }

        // Compare children recursively
        let childrenA = readerA.children.sorted(by: { $0.nodeInfo < $1.nodeInfo })
        let childrenB = readerB.children.sorted(by: { $0.nodeInfo < $1.nodeInfo })

        guard childrenA.count == childrenB.count else {
            return false
        }

        for (childA, childB) in zip(childrenA, childrenB) {
            if childA.nodeInfo != childB.nodeInfo || !compareReaders(childA, childB) {
                return false
            }
        }

        return true
    }

    fileprivate static func anyCBORValuesAreEqual(_ lhs: CBORType?, _ rhs: CBORType?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case (nil, _), (_, nil):
            return false
        case (.null, .null):
            return true
        case (.undefined, .undefined):
            return true
        case (.bool(let lVal), .bool(let rVal)):
            return lVal == rVal
        case (.text(let lVal), .text(let rVal)):
            return lVal == rVal
        case (.bytes(let lVal), .bytes(let rVal)):
            return lVal == rVal
        case (.date(let lVal), .date(let rVal)):
            return lVal == rVal
        case (.tag(let lVal), .tag(let rVal)):
            return lVal == rVal

        // Numeric comparisons
        case (.uint(let lVal), .uint(let rVal)):
            return lVal == rVal
        case (.int(let lVal), .int(let rVal)):
            return lVal == rVal
        case (.double(let lVal), .double(let rVal)):
            return (lVal.isNaN && rVal.isNaN) || lVal == rVal

        // Cross-type numeric comparisons
        case (.uint(let lVal), .double(let rVal)):
            return Double(lVal) == rVal
        case (.int(let lVal), .double(let rVal)):
            return Double(lVal) == rVal
        case (.double(let lVal), .uint(let rVal)):
            return lVal == Double(rVal)
        case (.double(let lVal), .int(let rVal)):
            return lVal == Double(rVal)
        case (.uint(let lVal), .int(let rVal)):
            return rVal >= 0 && UInt64(rVal) == lVal
        case (.int(let lVal), .uint(let rVal)):
            return lVal >= 0 && UInt64(lVal) == rVal

        // Arrays
        case (.array(let lArr), .array(let rArr)):
            return anyCBORArraysAreEqual(lArr, rArr)

        // Maps
        case (.map(let lMap), .map(let rMap)):
            return anyCBORDictsAreEqual(lMap, rMap)

        // Indefinite types
        case (.indef_map_start, .indef_map_start),
             (.indef_text_start, .indef_text_start),
             (.indef_array_start, .indef_array_start),
             (.indef_bytes_start, .indef_bytes_start),
             (.indef_break, .indef_break):
            return true

        default:
            return false
        }
    }

    fileprivate static func anyCBORArraysAreEqual(_ lhs: [CBORType], _ rhs: [CBORType]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        for i in 0..<lhs.count {
            if !anyCBORValuesAreEqual(lhs[i], rhs[i]) {
                return false
            }
        }
        return true
    }

    fileprivate static func anyCBORDictsAreEqual(_ lhs: [String: CBORType], _ rhs: [String: CBORType]) -> Bool {
        // Keys must match exactly. Order does not matter.
        guard lhs.keys.sorted() == rhs.keys.sorted() else { return false }
        for key in lhs.keys {
            if !anyCBORValuesAreEqual(lhs[key], rhs[key]) {
                return false
            }
        }
        return true
    }
}
