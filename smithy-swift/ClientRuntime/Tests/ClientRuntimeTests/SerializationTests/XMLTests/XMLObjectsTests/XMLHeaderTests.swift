//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

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
