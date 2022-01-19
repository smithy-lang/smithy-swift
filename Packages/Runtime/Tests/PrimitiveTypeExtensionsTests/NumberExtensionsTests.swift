/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import Runtime

class NumberExtensionsTests: XCTestCase {
    func testEncodeDouble() {
        let regularDouble: Double = 6.0
        XCTAssertEqual(regularDouble.encoded(), "6.0")
    }
    
    func testEncodeDoubleInteger() {
        let regularIntAsDouble: Double = 6
        XCTAssertEqual(regularIntAsDouble.encoded(), "6.0")
    }
    
    func testEncodeDoubleNan() {
        let nanDouble = Double.nan
        XCTAssertEqual(nanDouble.encoded(), "NaN")
    }
    
    func testEncodeDoubleInfinity() {
        let doubleInfinity = Double.infinity
        XCTAssertEqual(doubleInfinity.encoded(), "Infinity")
    }
    
    func testEncodeDoubleInfinityNegative() {
        let doubleInfinityNegative = -Double.infinity
        XCTAssertEqual(doubleInfinityNegative.encoded(), "-Infinity")
    }
    
    func testEncodeFloat() {
        let regularFloat: Float = 6.0
        XCTAssertEqual(regularFloat.encoded(), "6.0")
    }
    
    func testEncodeFloatInteger() {
        let regularFloatAsInt: Float = 6
        XCTAssertEqual(regularFloatAsInt.encoded(), "6.0")
    }
    
    func testEncodeFloatNan() {
        let nanFloat = Float.nan
        XCTAssertEqual(nanFloat.encoded(), "NaN")
    }
    
    func testEncodeFloatInfinity() {
        let floatInfinity = Float.infinity
        XCTAssertEqual(floatInfinity.encoded(), "Infinity")
    }
    
    func testEncodeFloatInfinityNegative() {
        let floatInfinityNegative = -Float.infinity
        XCTAssertEqual(floatInfinityNegative.encoded(), "-Infinity")
    }
}
