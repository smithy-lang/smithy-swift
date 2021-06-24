//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
import XCTest
@testable import ClientRuntime

class FormURLEncoderTests: XCTestCase {
    
    func testFlattenedList() {
        let flattenedListArg = ["listArgFlat1", "listArgFlat2"]
        let payload = QueryListsInput(flattenedListArg: flattenedListArg)
        let encoder = FormURLEncoder()

        let actualData = try! encoder.encode(payload)
        let actualDataString = String(data: actualData, encoding: .utf8)!

        let expectedString = """
        FlattenedListArg.1=listArgFlat1
        &FlattenedListArg.2=listArgFlat2
        """
        XCTAssertEqual(expectedString, actualDataString)
    }

    func testWrappedList() {
        let listArg = ["listArg1", "listArg2"]
        let payload = QueryListsInput(listArg: listArg)
        let encoder = FormURLEncoder()

        let actualData = try! encoder.encode(payload)
        let actualDataString = String(data: actualData, encoding: .utf8)!

        let expectedString = """
        ListArg.member.1=listArg1
        &ListArg.member.2=listArg2
        """
        XCTAssertEqual(expectedString, actualDataString)
    }
    
    func testFlattenedMap() {
        let flattenedMap = ["first": "hello",
                            "second": "konnichiwa"]
        let payload = QueryMapsInput(flattenedMap: flattenedMap)
        let encoder = FormURLEncoder()

        let actualData = try! encoder.encode(payload)
        let actualDataString = String(data: actualData, encoding: .utf8)!

        let expectedStrings = ["""
        FlattenedMap.1.key=first
        &FlattenedMap.1.value=hello
        &FlattenedMap.2.key=second
        &FlattenedMap.2.value=konnichiwa
        """,
        """
        FlattenedMap.1.key=second
        &FlattenedMap.1.value=konnichiwa
        &FlattenedMap.2.key=first
        &FlattenedMap.2.value=hello
        """                              ]
        XCTAssert(expectedStrings.contains(actualDataString))
    }

    func testWrappedMap() {
        let mapArg = ["first": "hello",
                      "second": "konnichiwa"]
        let payload = QueryMapsInput(mapArg: mapArg)
        let encoder = FormURLEncoder()

        let actualData = try! encoder.encode(payload)
        let actualDataString = String(data: actualData, encoding: .utf8)!

        let expectedStrings = ["""
        MapArg.entry.1.key=first
        &MapArg.entry.1.value=hello
        &MapArg.entry.2.key=second
        &MapArg.entry.2.value=konnichiwa
        """,
        """
        MapArg.entry.1.key=second
        &MapArg.entry.1.value=konnichiwa
        &MapArg.entry.2.key=first
        &MapArg.entry.2.value=hello
        """                         ]
        XCTAssert(expectedStrings.contains(actualDataString))
    }
}
