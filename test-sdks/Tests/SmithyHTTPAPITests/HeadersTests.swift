//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyHTTPAPI
import XCTest

class HeadersTests: XCTestCase {

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

    // MARK: - exists()

    func test_exists_trueIfHeaderExists() {
        let subject = Headers(["a": "abc"])
        XCTAssertTrue(subject.exists(name: "a"))
    }

    func test_exists_falseIfHeaderDoesntExist() {
        let subject = Headers(["a": "abc"])
        XCTAssertFalse(subject.exists(name: "b"))
    }

    func test_exists_trueIfHeaderValueIsEmptyString() {
        let subject = Headers(["a": ""])
        XCTAssertTrue(subject.exists(name: "a"))
    }

    func test_exists_trueIfHeaderValueIsEmptyList() {
        let subject = Headers(["a": []])
        XCTAssertTrue(subject.exists(name: "a"))
    }

    // MARK: - Case-insensitive name matching

    func test_values_matchesNameIgnoringASCIICase() {
        let subject = Headers(["X-Amz-Checksum-CRC32": "abc"])
        XCTAssertEqual(subject.values(for: "x-amz-checksum-crc32"), ["abc"])
        XCTAssertEqual(subject.values(for: "X-AMZ-CHECKSUM-CRC32"), ["abc"])
    }

    func test_values_doesNotMatchANameThatIsOnlyAPrefix() {
        // Header names in the wild routinely share a prefix, i.e. these two from S3.
        var subject = Headers(["x-amz-checksum-crc32": "abc"])
        subject.add(name: "x-amz-checksum-crc32c", value: "def")
        XCTAssertEqual(subject.values(for: "x-amz-checksum-crc32"), ["abc"])
        XCTAssertEqual(subject.values(for: "x-amz-checksum-crc32c"), ["def"])
        XCTAssertNil(subject.values(for: "x-amz-checksum-crc32cc"))
    }

    func test_values_doesNotMatchANameDifferingByANonLetter() {
        // `-` and a carriage return differ only in the bit that distinguishes ASCII letter case.
        let subject = Headers(["a-b": "abc"])
        XCTAssertNil(subject.values(for: "a\rb"))
    }

    func test_values_concatenatesTheValuesOfEveryMatchingHeader() {
        var subject = Headers()
        // `addAll` appends without merging, so a name may appear more than once.
        subject.addAll(headers: Headers(["Repeated": "first"]))
        subject.addAll(headers: Headers(["repeated": "second"]))
        XCTAssertEqual(subject.values(for: "REPEATED"), ["first", "second"])
    }
}
