//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

public func XCTAssertJSONDataEqual(
    _ expression1: @autoclosure () throws -> Data,
    _ expression2: @autoclosure () throws -> Data,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    do {
        let data1 = try expression1()
        let data2 = try expression2()
        guard data1 != data2 else { return }
        let jsonDict1 = try JSONSerialization.jsonObject(with: data1)
        let jsonDict2 = try JSONSerialization.jsonObject(with: data2)
        XCTAssertTrue(anyValuesAreEqual(jsonDict1, jsonDict2), message(), file: file, line: line)
    } catch {
        XCTFail("Failed to evaluate JSON with error: \(error)", file: file, line: line)
    }
}

public func XCTAssertXMLDataEqual(
    _ expression1: @autoclosure () throws -> Data,
    _ expression2: @autoclosure () throws -> Data,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    do {
        let data1 = try expression1()
        let data2 = try expression2()
        guard data1 != data2 else { return }
        XCTAssertTrue(XMLComparator.xmlData(data1, isEqualTo: data2), message(), file: file, line: line)
    } catch {
        XCTFail("Failed to evaluate XML with error: \(error)", file: file, line: line)
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


