/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
import ClientRuntime

class HttpHeadersTests: XCTestCase {

    var headersAsDictionaryWithArray = [String: [String]]()
    var headersAsDictionary = [String: String]()
    let testURL = URL(string: "foo://mytest.com")!

    override func setUp() {
        headersAsDictionaryWithArray["header-item-1"] = ["header-value-1"]
        headersAsDictionary["header-item-1"] = "header-value-1"
    }

    func testInitWithDictionary() {
        let httpHeaders = Headers(headersAsDictionaryWithArray)

        XCTAssertEqual(httpHeaders.dictionary, headersAsDictionaryWithArray)
    }

    func testAddNameValuePairAsHeaderItem() {
        var httpHeaders = Headers(headersAsDictionaryWithArray)
        httpHeaders.add(name: "header-item-2", value: "header-value-2")

        headersAsDictionaryWithArray["header-item-2"] = ["header-value-2"]

        XCTAssertEqual(httpHeaders.dictionary, headersAsDictionaryWithArray)
    }

    func testUpdateHeaderItem() {
        var httpHeaders = Headers(headersAsDictionaryWithArray)
        let updatedHttpHeader = Header(name: "header-item-1", value: "header-1-value")

        httpHeaders.update(updatedHttpHeader)

        headersAsDictionaryWithArray["header-item-1"] = ["header-1-value"]

        XCTAssertEqual(httpHeaders.dictionary, headersAsDictionaryWithArray)
    }

    func testAddingExistingHeaderUpdatesIt() {
        var httpHeaders = Headers(headersAsDictionaryWithArray)
        httpHeaders.add(name: "header-item-1", value: "header-1-value")

        headersAsDictionaryWithArray["header-item-1"]?.append("header-1-value")

        XCTAssertEqual(httpHeaders.dictionary, headersAsDictionaryWithArray)
    }

    func testCaseInsensitiveHeaderValueFetchingFromName() {
        let httpHeaders = Headers(headersAsDictionary)
        let headerValue = httpHeaders.value(for: "Header-Item-1")

        XCTAssertEqual(headerValue, headersAsDictionary["header-item-1"])
    }
    func testRemoveHeaderWithName() {
        var httpHeaders = Headers(headersAsDictionaryWithArray)
        httpHeaders.remove(name: "header-item-1")

        XCTAssertEqual(httpHeaders.dictionary.count, 0)
    }

    // MARK: - Equatable & Hashable implementations

    func test_headers_equatableAndHashable_nonIdenticalHeaders() {
        var headersA = Headers()
        headersA.add(name: "A", values: ["X", "Y"])
        var headersB = Headers()
        headersB.add(name: "B", values: ["X", "Y"])

        XCTAssertNotEqual(headersA, headersB)
    }

    func test_headers_equatableAndHashable_identicalHeaders() {
        var headersA = Headers()
        headersA.add(name: "A", values: ["X", "Y"])
        headersA.add(name: "B", values: ["X", "Y"])
        var headersB = Headers()
        headersB.add(name: "A", values: ["X", "Y"])
        headersB.add(name: "B", values: ["X", "Y"])

        XCTAssertEqual(headersA, headersB)
        XCTAssertEqual(headersA.hashValue, headersB.hashValue)
    }

    func test_headers_equatableAndHashable_outOfOrderHeaders() {
        var headersA = Headers()
        headersA.add(name: "A", values: ["X", "Y"])
        headersA.add(name: "B", values: ["X", "Y"])
        var headersB = Headers()
        headersB.add(name: "B", values: ["X", "Y"])
        headersB.add(name: "A", values: ["X", "Y"])

        XCTAssertEqual(headersA, headersB)
        XCTAssertEqual(headersA.hashValue, headersB.hashValue)
    }

    func test_header_equatableAndHashable_nonIdenticalValues() {
        let headerA = Header(name: "A", values: ["X", "Y"])
        let headerB = Header(name: "B", values: ["X", "Y"])

        XCTAssertNotEqual(headerA, headerB)
    }

    func test_header_equatableAndHashable_identicalValues() {
        let headerA = Header(name: "A", values: ["X", "Y"])
        let headerB = Header(name: "A", values: ["X", "Y"])

        XCTAssertEqual(headerA, headerB)
        XCTAssertEqual(headerA.hashValue, headerB.hashValue)
    }

    func test_header_equatableAndHashable_outOfOrderValues() {
        let headerA = Header(name: "A", values: ["X", "Y"])
        let headerB = Header(name: "A", values: ["Y", "X"])

        XCTAssertEqual(headerA, headerB)
        XCTAssertEqual(headerA.hashValue, headerB.hashValue)
    }
}
