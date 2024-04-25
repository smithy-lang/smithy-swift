//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyTestUtil
import XCTest

class DoubleAndFloatEquivalenceCheckerTests : XCTestCase {
    private var double1: Double?
    private var double2: Double?

    func testDoublesMatchBothNil() {
        XCTAssertTrue(doublesMatch(lhs: double1, rhs: double2))
    }
    func testDoublesMatchOneNilLHS() {
        double1 = 3.0
        XCTAssertFalse(doublesMatch(lhs: double1, rhs: double2))
    }
    func testDoublesMatchOneNilRHS() {
        double2 = 3.0
        XCTAssertFalse(doublesMatch(lhs: double1, rhs: double2))
    }
    func testDoublesMatchBothNaN() {
        double1 = .infinity
        double2 = .infinity
        XCTAssertTrue(doublesMatch(lhs: double1, rhs: double2))
    }
    func testDoublesMatchOneNaNLHS() {
        double1 = .infinity
        XCTAssertFalse(doublesMatch(lhs: double1, rhs: double2))
    }
    func testDoublesMatchOneNaNRHS() {
        double2 = .infinity
        XCTAssertFalse(doublesMatch(lhs: double1, rhs: double2))
    }
    func testDoublesMatchDiffValues() {
        double1 = 3.0
        double2 = 1.0
        XCTAssertFalse(doublesMatch(lhs: double1, rhs: double2))
    }
    func testDoublesMatchSameValues() {
        double1 = 3.0
        double2 = 3.0
        XCTAssertTrue(doublesMatch(lhs: double1, rhs: double2))
    }

    private var float1: Float?
    private var float2: Float?

    func testFloatsMatchBothNil() {
        XCTAssertTrue(floatsMatch(lhs: float1, rhs: float2))
    }
    func testFloatsMatchOneNilLHS() {
        float1 = 3.0
        XCTAssertFalse(floatsMatch(lhs: float1, rhs: float2))
    }
    func testFloatsMatchOneNilRHS() {
        float2 = 3.0
        XCTAssertFalse(floatsMatch(lhs: float1, rhs: float2))
    }
    func testFloatsMatchBothNaN() {
        float1 = .infinity
        float2 = .infinity
        XCTAssertTrue(floatsMatch(lhs: float1, rhs: float2))
    }
    func testFloatsMatchOneNaNLHS() {
        float1 = .infinity
        XCTAssertFalse(floatsMatch(lhs: float1, rhs: float2))
    }
    func testFloatsMatchOneNaNRHS() {
        float2 = .infinity
        XCTAssertFalse(floatsMatch(lhs: float1, rhs: float2))
    }
    func testFloatsMatchDiffValues() {
        float1 = 3.0
        float2 = 1.0
        XCTAssertFalse(floatsMatch(lhs: float1, rhs: float2))
    }
    func testFloatsMatchSameValues() {
        float1 = 3.0
        float2 = 3.0
        XCTAssertTrue(floatsMatch(lhs: float1, rhs: float2))
    }
}
