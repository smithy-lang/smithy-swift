//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SmithyXML) import SmithyXML

class XMLFloatEncoderTests: XCTestCase {

    private struct HasFPElements: Encodable {
        let f: Float
        let d: Double
    }

    func test_serializesInfinity() throws {
        let fp = HasFPElements(f: .infinity, d: .infinity)
        let xmlData = try XMLEncoder().encode(fp, rootElement: "fp")
        let doc = try XMLDocument(data: xmlData)
        print(String(data: xmlData, encoding: .utf8)!)
        XCTAssertEqual(value(document: doc, member: "f"), "Infinity")
        XCTAssertEqual(value(document: doc, member: "d"), "Infinity")
    }

    func test_serializesNegativeInfinity() throws {
        let fp = HasFPElements(f: -.infinity, d: -.infinity)
        let xmlData = try XMLEncoder().encode(fp, rootElement: "fp")
        let doc = try XMLDocument(data: xmlData)
        print(String(data: xmlData, encoding: .utf8)!)
        XCTAssertEqual(value(document: doc, member: "f"), "-Infinity")
        XCTAssertEqual(value(document: doc, member: "d"), "-Infinity")
    }

    func test_serializesNaN() throws {
        let fp = HasFPElements(f: .nan, d: .nan)
        let xmlData = try XMLEncoder().encode(fp, rootElement: "fp")
        let doc = try XMLDocument(data: xmlData)
        print(String(data: xmlData, encoding: .utf8)!)
        XCTAssertEqual(value(document: doc, member: "f"), "NaN")
        XCTAssertEqual(value(document: doc, member: "d"), "NaN")
    }

    private func value(document: XMLDocument, member: String) -> String? {
        document.children?.first { $0.name == "fp" }?.children?.first { $0.name == member }?.stringValue
    }
}
