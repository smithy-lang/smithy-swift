//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import SmithyXML

class FloatReaderTests: XCTestCase {

    struct Numbers {
        var floatInfinity: Float?
        var floatNegativeInfinity: Float?
        var floatNaN: Float?
        var doubleInfinity: Double?
        var doubleNegativeInfinity: Double?
        var doubleNaN: Double?

        static func readingClosure(from reader: Reader) throws -> Numbers {
            var value = Numbers()
            value.floatInfinity = try reader[.init("FloatInfinity")].read()
            value.floatNegativeInfinity = try reader[.init("FloatNegativeInfinity")].read()
            value.floatNaN = try reader[.init("FloatNaN")].read()
            value.doubleInfinity = try reader[.init("DoubleInfinity")].read()
            value.doubleNegativeInfinity = try reader[.init("DoubleNegativeInfinity")].read()
            value.doubleNaN = try reader[.init("DoubleNaN")].read()
            return value
        }
    }

    let xmlData = Data("""
<Numbers>
    <FloatInfinity>Infinity</FloatInfinity>
    <FloatNegativeInfinity>-Infinity</FloatNegativeInfinity>
    <FloatNaN>NaN</FloatNaN>
    <DoubleInfinity>Infinity</DoubleInfinity>
    <DoubleNegativeInfinity>-Infinity</DoubleNegativeInfinity>
    <DoubleNaN>NaN</DoubleNaN>
</Numbers>
""".utf8)

    var reader: Reader!
    var numbers: Numbers!

    override func setUpWithError() throws {
        try super.setUpWithError()
        reader = try Reader.from(data: xmlData)
        numbers = try Numbers.readingClosure(from: reader)
    }

    func test_readsInfiniteFloat() throws {
        XCTAssertEqual(numbers.floatInfinity, .infinity)
    }

    func test_readsNegativeInfiniteFloat() throws {
        XCTAssertEqual(numbers.floatNegativeInfinity, -.infinity)
    }

    func test_readsNaNFloat() throws {
        XCTAssertTrue(numbers.floatNaN?.isNaN ?? false)
    }

    func test_readsInfiniteDouble() throws {
        XCTAssertEqual(numbers.doubleInfinity, .infinity)
    }

    func test_readsNegativeInfiniteDouble() throws {
        XCTAssertEqual(numbers.doubleNegativeInfinity, -.infinity)
    }

    func test_readsNaNDouble() throws {
        XCTAssertTrue(numbers.doubleNaN?.isNaN ?? false)
    }
}
