//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct JSONComparator {
    /// Returns true if the JSON documents, for the corresponding data objects, are equal.
    /// - Parameters:
    ///   - dataA: The first data object to compare to the second data object.
    ///   - dataB: The second data object to compare to the first data object.
    /// - Returns: Returns true if the JSON documents, for the corresponding data objects, are equal.
    public static func jsonData(_ dataA: Data, isEqualTo dataB: Data) throws -> Bool {
        let jsonDictA = try JSONSerialization.jsonObject(with: dataA, options: [.fragmentsAllowed])
        let jsonDictB = try JSONSerialization.jsonObject(with: dataB, options: [.fragmentsAllowed])
        return anyValuesAreEqual(jsonDictA, jsonDictB)
    }
}

fileprivate func anyDictsAreEqual(_ lhs: [String: Any], _ rhs: [String: Any]) -> Bool {
    guard lhs.keys == rhs.keys else { return false }
    for key in lhs.keys {
        if !anyValuesAreEqual(lhs[key], rhs[key]) {
            return false
        }
    }
    return true
}

fileprivate func anyArraysAreEqual(_ lhs: [Any], _ rhs: [Any]) -> Bool {
    guard lhs.count == rhs.count else { return false }
    for i in 0..<lhs.count {
        if !anyValuesAreEqual(lhs[i], rhs[i]) {
            return false
        }
    }
    return true
}

fileprivate func anyValuesAreEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
    if lhs == nil && rhs == nil { return true }
    guard let lhs = lhs, let rhs = rhs else { return false }
    if let lhsDict = lhs as? [String: Any], let rhsDict = rhs as? [String: Any] {
        return anyDictsAreEqual(lhsDict, rhsDict)
    } else if let lhsArray = lhs as? [Any], let rhsArray = rhs as? [Any] {
        return anyArraysAreEqual(lhsArray, rhsArray)
    } else {
        return type(of: lhs) == type(of: rhs) && "\(lhs)" == "\(rhs)"
    }
}
