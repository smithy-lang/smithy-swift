/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class XMLHeaderTests: XCTestCase {

    func testInitWithVersionEncodingStandalone() {
        let header = XMLHeader(version: 1.0, encoding: "UTF-8", standalone: "yes")
        XCTAssertEqual(header.version, 1.0)
        XCTAssertEqual(header.encoding, "UTF-8")
        XCTAssertEqual(header.standalone, "yes")
    }

    func testInitWithVersionEncoding() {
        let header = XMLHeader(version: 1.0, encoding: "UTF-8")
        XCTAssertEqual(header.version, 1.0)
        XCTAssertEqual(header.encoding, "UTF-8")
        XCTAssertNil(header.standalone)
    }

    func testInitWithVersion() {
        let header = XMLHeader(version: 1.0)
        XCTAssertEqual(header.version, 1.0)
        XCTAssertNil(header.encoding)
        XCTAssertNil(header.standalone)
    }

    func testDefaultInit() {
        let header = XMLHeader()
        XCTAssertNil(header.version)
        XCTAssertNil(header.encoding)
        XCTAssertNil(header.standalone)
    }

    func testHeaderIsEmpty() {
        let emptyHeader = XMLHeader()
        XCTAssertTrue(emptyHeader.isEmpty())

        let nonEmptyHeader = XMLHeader(version: 1.0)
        XCTAssertFalse(nonEmptyHeader.isEmpty())
    }

    func testHeaderToXML() {
        let emptyHeader = XMLHeader()
        XCTAssertNil(emptyHeader.toXML())

        let headerWithVersion = XMLHeader(version: 1.0)
        XCTAssertEqual(headerWithVersion.toXML(), "<?xml version=\"1.0\"?>\n")

        let headerWithVersionEncoding = XMLHeader(version: 1.0, encoding: "UTF-8")
        XCTAssertEqual(headerWithVersionEncoding.toXML(), "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")

        let headerWithVersionEncodingStandalone = XMLHeader(version: 1.0, encoding: "UTF-8", standalone: "yes")
        XCTAssertEqual(headerWithVersionEncodingStandalone.toXML(), "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n")
    }
}
