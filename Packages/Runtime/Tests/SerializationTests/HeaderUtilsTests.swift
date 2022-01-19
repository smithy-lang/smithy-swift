/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
import Runtime

class HeaderUtilsTests: XCTestCase {
    
    func testSplitHeaderListValues() {
        guard let headerCollectionValues = splitHeaderListValues("1") else {
            XCTFail("splitting header list values unexpectedly returned nil")
            return
        }
        XCTAssertEqual([1], headerCollectionValues.map { Int($0) })
        XCTAssertEqual([1, 2, 3], splitHeaderListValues("1,2,3")?.map { Int($0) })
        // Trim whitespaces in beginning and end of string components
        XCTAssertEqual([1, 2, 3], splitHeaderListValues(" 1, 2, 3 ")?.map { Int($0) })
        XCTAssertEqual([nil, 1], splitHeaderListValues(",1")?.map { Int($0) })
    }
    
    func testSplitHttpDateHeaderListValues() {
        let dateHeaderTransformations = [
            "Mon, 16 Dec 2019 23:48:18 GMT": ["Mon, 16 Dec 2019 23:48:18 GMT"],
            "Mon, 16 Dec 2019 23:48:18 GMT, Tue, 17 Dec 2019 23:48:18 GMT": [
                "Mon, 16 Dec 2019 23:48:18 GMT",
                "Tue, 17 Dec 2019 23:48:18 GMT"
            ],
            "": [""]
        ]
        
        for (headerListString, headerList) in dateHeaderTransformations {
            XCTAssertEqual(headerList, try? splitHttpDateHeaderListValues(headerListString))
        }
    }
}
