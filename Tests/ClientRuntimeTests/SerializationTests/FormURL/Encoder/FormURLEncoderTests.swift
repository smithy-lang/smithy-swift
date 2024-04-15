//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyFormURL
import XCTest
@testable import ClientRuntime

class FormURLEncoderTests: XCTestCase {

    func testFlattenedList() throws {
        let flattenedListArg = ["listArgFlat1", "listArgFlat2"]
        let payload = QueryListsInput(flattenedListArg: flattenedListArg)
        let writer = SmithyFormURL.Writer(nodeInfo: "")

        try QueryListsInput.write(value: payload, to: writer)

        let actualData = try writer.data()
        let actualDataString = String(data: actualData, encoding: .utf8)!

        let expectedString = """
        FlattenedListArg.1=listArgFlat1&FlattenedListArg.2=listArgFlat2
        """
        XCTAssertEqual(expectedString, actualDataString)
    }

    func testWrappedList() throws {
        let listArg = ["listArg1", "listArg2"]
        let payload = QueryListsInput(listArg: listArg)
        let writer = SmithyFormURL.Writer(nodeInfo: "")

        try QueryListsInput.write(value: payload, to: writer)

        let actualData = try writer.data()
        let actualDataString = String(data: actualData, encoding: .utf8)!

        let expectedString = """
        ListArg.member.1=listArg1&ListArg.member.2=listArg2
        """
        XCTAssertEqual(expectedString, actualDataString)
    }

    func testFlattenedMap() throws {
        let flattenedMap = ["first": "hello",
                            "second": "konnichiwa"]
        let payload = QueryMapsInput(flattenedMap: flattenedMap)
        let writer = SmithyFormURL.Writer(nodeInfo: "")

        try QueryMapsInput.write(value: payload, to: writer)

        let actualData = try writer.data()
        let actualDataString = String(data: actualData, encoding: .utf8)!

        let expectedString = """
        FlattenedMap.1.key=first&FlattenedMap.1.value=hello&FlattenedMap.2.key=second&FlattenedMap.2.value=konnichiwa
        """
        XCTAssertEqual(expectedString, actualDataString)
    }

    func testWrappedMap() throws {
        let mapArg = ["first": "hello",
                      "second": "konnichiwa"]
        let payload = QueryMapsInput(mapArg: mapArg)
        let writer = SmithyFormURL.Writer(nodeInfo: "")

        try QueryMapsInput.write(value: payload, to: writer)

        let actualData = try writer.data()
        let actualDataString = String(data: actualData, encoding: .utf8)!

        let expectedString = """
        MapArg.entry.1.key=first&MapArg.entry.1.value=hello&MapArg.entry.2.key=second&MapArg.entry.2.value=konnichiwa
        """
        XCTAssertEqual(expectedString, actualDataString)
    }
}
