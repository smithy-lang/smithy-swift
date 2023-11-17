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

func AssertXMLDataEqual(_ lhs: Data, _ rhs: Data, file: StaticString = #file, line: UInt = #line) throws {
    let lhsDoc = try XMLDocument(data: lhs)
    let rhsDoc = try XMLDocument(data: rhs)
    XCTAssertEqual(lhsDoc, rhsDoc, file: file, line: line)
}
