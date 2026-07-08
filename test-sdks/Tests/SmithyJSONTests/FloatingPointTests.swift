//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SmithyReadWrite) import SmithyReadWrite
@_spi(SmithyReadWrite) import SmithyJSON

// It appears that the doubleValue property on NSNumber & its associated types can sometimes lose
// precision from the original number.
//
// This set of tests is intended to verify that Doubles and Floats can be read accurately from JSON.

final class FloatingPointTests: XCTestCase {
    var originalFloats = [Float]()
    var floatData = Data()
    var originalDoubles = [Double]()
    var doubleData = Data()

    // Renders 250 floats & doubles to JSON arrays.  Numbers are random so they will
    // likely use all available decimal places.
    override func setUp() {
        super.setUp()
        originalFloats = (1..<250).map { _ in Float.random(in: 0.0...1.0) }
        originalDoubles = (1..<250).map { _ in Double.random(in: 0.0...1.0) }
        floatData = try! JSONEncoder().encode(originalFloats)
        doubleData = try! JSONEncoder().encode(originalDoubles)
    }

    func test_floatRead() throws {
        let reader = try Reader.from(data: floatData)
        let floats = try reader.readList(memberReadingClosure: ReadingClosures.readFloat(from:), memberNodeInfo: "", isFlattened: false)
        XCTAssert(floats == originalFloats)
    }

    func test_doubleRead() throws {
        let reader = try Reader.from(data: doubleData)
        let doubles = try reader.readList(memberReadingClosure: ReadingClosures.readDouble(from:), memberNodeInfo: "", isFlattened: false)
        XCTAssert(doubles == originalDoubles)
    }
}
