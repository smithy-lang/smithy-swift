//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
import XCTest
import ClientRuntime

class TimestampWrapperTests: XCTestCase {
    func testSplitHeaderListValues() {
        let date = Date(timeIntervalSince1970: 1422172800)
        let wrappedTimestamp = TimestampWrapper(date, format: .epochSeconds)
        let encoded = try! JSONEncoder().encode(wrappedTimestamp)
        guard let jsonString = String(data: encoded, encoding: .utf8) else {
            XCTFail("Failed to encode json String")
            return
        }

        XCTAssertEqual("[\"1422172800\"]", jsonString)
    }
}
