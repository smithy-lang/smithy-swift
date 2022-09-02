/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
import SmithyClientRuntime

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
}
