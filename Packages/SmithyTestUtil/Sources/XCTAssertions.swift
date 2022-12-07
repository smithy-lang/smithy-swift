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
        XCTAssertTrue(
            try JSONComparator.jsonData(data1, isEqualTo: data2),
            message(),
            file: file,
            line: line
        )
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
