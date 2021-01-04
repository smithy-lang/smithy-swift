/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class DictionaryExtensionsTests: XCTestCase {
    
    func testDictionaryExtension() {
        var dict = [String: Int]()
        dict["Test"] = 1
        dict["Slam"] = 2
        dict["WHUT"] = 3
        
        let firstKVPair = dict[0]
        let secondKVPair = dict[1]
        let thirdKVPair = dict[2]
        XCTAssert(firstKVPair.key == "Test" && firstKVPair.value == 1)
        XCTAssert(secondKVPair.key == "Slam" && secondKVPair.value == 2)
        XCTAssert(thirdKVPair.key == "WHUT" && thirdKVPair.value == 3)
    }
}
