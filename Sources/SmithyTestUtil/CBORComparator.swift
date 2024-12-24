//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
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

//    private static func areMapsEqual(_ mapA: [String: CBORType], _ mapB: [String: CBORType]) -> Bool {
//        // Ensure the keys match
//        guard Set(mapA.keys) == Set(mapB.keys) else { return false }
//
//        // Compare values for each key
//        for key in mapA.keys {
//            guard let valueA = mapA[key], let valueB = mapB[key] else {
//                return false
//            }
//
//            switch (valueA, valueB) {
//            case (.map(let nestedMapA), .map(let nestedMapB)):
//                if !areMapsEqual(nestedMapA, nestedMapB) {
//                    return false
//                }
////            case (.array(let nestedArrayA), .array(let nestedArrayB)):
////                if !areArraysEqual(nestedArrayA, nestedArrayB) {
////                    return false
////                }
//            default:
//                if valueA != valueB && String(describing: valueA) != String(describing: valueB) {
//                    return false
//                }
//            }
//        }
//        return true
//    }

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

//public struct CBORComparator {
//    /// Returns true if the CBOR documents, for the corresponding data objects, are equal.
//    /// - Parameters:
//    ///   - dataA: The first CBOR data object to compare.
//    ///   - dataB: The second CBOR data object to compare.
//    /// - Returns: Returns true if the CBOR documents are equal.
//    public static func cborData(_ dataA: Data, isEqualTo dataB: Data) throws -> Bool {
//        let decodedA = try CBORDecoder(data: [UInt8](dataA))
//        let decodedB = try CBORDecoder(data: [UInt8](dataB))
//        while decodedA.hasNext() && decodedB.hasNext() {
//            let valueA = try decodedA.popNext()
//            let valueB = try decodedB.popNext()
//            if !anyCBORValuesAreEqual(valueA, valueB) {
//                return false
//            }
//        }
//        if decodedA.hasNext() || decodedB.hasNext() {
//            return false // unequal lengths
//        }
//        return true
//    }
//}
//
//fileprivate func anyCBORValuesAreEqual(_ lhs: CBORType?, _ rhs: CBORType?) -> Bool {
//    switch (lhs, rhs) {
//    case (nil, nil):
//        return true
//    case (nil, _), (_, nil):
//        return false
//    case (.null, .null):
//        return true
//    case (.undefined, .undefined):
//        return true
//    case (.bool(let lVal), .bool(let rVal)):
//        return lVal == rVal
//    case (.text(let lVal), .text(let rVal)):
//        return lVal == rVal
//    case (.bytes(let lVal), .bytes(let rVal)):
//        return lVal == rVal
//    case (.date(let lVal), .date(let rVal)):
//        return lVal == rVal
//    case (.tag(let lVal), .tag(let rVal)):
//        return lVal == rVal
//
//    case (.uint(let lVal), .uint(let rVal)):
//        return lVal == rVal
//    case (.int(let lVal), .int(let rVal)):
//        return lVal == rVal
//    case (.double(let lVal), .double(let rVal)):
//        return lVal == rVal
//
//    // Extended cross-type numeric comparisons
//    case (.uint(let lVal), .int(let rVal)):
//        guard rVal >= 0 else { return false }
//        return UInt64(rVal) == lVal
//    case (.int(let lVal), .uint(let rVal)):
//        guard lVal >= 0 else { return false }
//        return UInt64(lVal) == rVal
//    case (.uint(let lVal), .double(let rVal)):
//        return Double(lVal) == rVal
//    case (.int(let lVal), .double(let rVal)):
//        return Double(lVal) == rVal
//    case (.double(let lVal), .uint(let rVal)):
//        return lVal == Double(rVal)
//    case (.double(let lVal), .int(let rVal)):
//        return lVal == Double(rVal)
//
//    // New equivalency for integer and float with the same value
//    case (.double(let lVal), .uint(let rVal)):
//        return lVal == Double(rVal)
//    case (.double(let lVal), .int(let rVal)):
//        return lVal == Double(rVal)
//    case (.uint(let lVal), .double(let rVal)):
//        return Double(lVal) == rVal
//    case (.int(let lVal), .double(let rVal)):
//        return Double(lVal) == rVal
//
//    case (.array(let lArr), .array(let rArr)):
//        return anyCBORArraysAreEqual(lArr, rArr)
//    case (.map(let lMap), .map(let rMap)):
//        return anyCBORDictsAreEqual(lMap, rMap)
//
//    case (.indef_map_start, .indef_map_start):
//        return true
//    case (.indef_text_start, .indef_text_start):
//        return true
//    case (.indef_array_start, .indef_array_start):
//        return true
//    case (.indef_bytes_start, .indef_bytes_start):
//        return true
//    case (.indef_break, .indef_break):
//        return true
//
//    default:
//        return false
//    }
//}
//
//fileprivate func anyCBORArraysAreEqual(_ lhs: [CBORType], _ rhs: [CBORType]) -> Bool {
//    guard lhs.count == rhs.count else { return false }
//    for i in 0..<lhs.count {
//        if !anyCBORValuesAreEqual(lhs[i], rhs[i]) {
//            return false
//        }
//    }
//    return true
//}
//
//fileprivate func anyCBORDictsAreEqual(_ lhs: [String: CBORType], _ rhs: [String: CBORType]) -> Bool {
//    // Keys must match exactly. Order does not matter.
//    guard lhs.keys.sorted() == rhs.keys.sorted() else { return false }
//    for key in lhs.keys {
//        if !anyCBORValuesAreEqual(lhs[key], rhs[key]) {
//            return false
//        }
//    }
//    return true
//}
