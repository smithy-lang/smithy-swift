//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(FoundationXML)
import class FoundationXML.XMLDocument
#endif
import XCTest
import SmithyXML

class XMLFloatEncoderTests: XCTestCase {

    private struct HasFPElements {

        static func write(_ value: HasFPElements, to writer: Writer) throws {
            try writer[.init("f")].write(value.f)
            try writer[.init("d")].write(value.d)
        }

        let f: Float
        let d: Double
    }

    func test_serializesInfinity() throws {
        let fp = HasFPElements(f: .infinity, d: .infinity)
        let data = try SmithyXML.XMLReadWrite.documentWritingClosure(
            rootNodeInfo: .init("fp")
        )(
            fp,
            HasFPElements.write(_:to:)
        )
        print(String(data: data, encoding: .utf8)!)
        let doc = try XMLDocument(data: data)
        XCTAssertEqual(value(document: doc, member: "f"), "Infinity")
        XCTAssertEqual(value(document: doc, member: "d"), "Infinity")
    }

    func test_serializesNegativeInfinity() throws {
        let fp = HasFPElements(f: -.infinity, d: -.infinity)
        let data = try SmithyXML.XMLReadWrite.documentWritingClosure(
            rootNodeInfo: .init("fp")
        )(
            fp,
            HasFPElements.write(_:to:)
        )
        print(String(data: data, encoding: .utf8)!)
        let doc = try XMLDocument(data: data)
        XCTAssertEqual(value(document: doc, member: "f"), "-Infinity")
        XCTAssertEqual(value(document: doc, member: "d"), "-Infinity")
    }

    func test_serializesNaN() throws {
        let fp = HasFPElements(f: .nan, d: .nan)
        let data = try SmithyXML.XMLReadWrite.documentWritingClosure(
            rootNodeInfo: .init("fp")
        )(
            fp,
            HasFPElements.write(_:to:)
        )
        print(String(data: data, encoding: .utf8)!)
        let doc = try XMLDocument(data: data)
        XCTAssertEqual(value(document: doc, member: "f"), "NaN")
        XCTAssertEqual(value(document: doc, member: "d"), "NaN")
    }

    private func value(document: XMLDocument, member: String) -> String? {
        document.children?.first { $0.name == "fp" }?.children?.first { $0.name == member }?.stringValue
    }
}
