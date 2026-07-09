//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import SmithyWaitersAPI

class JMESUtilsTests: XCTestCase {

    // MARK: - Equatable

    // Note that Swift has trouble resolving the `!=` operator
    // for `Double?`, `Double?` operand types (not for any other type).
    // Codegen will translate `!=` into `==` and negate the expression
    // to avoid a compile failure.
    //
    // Hence `Int` (which uses `Double` comparators) and `Double` are
    // not tested with `!=` below.

    func test_equateInt_handlesOptionalityCombos() async throws {
        let lhs: Int? = 1
        let rhs: Int? = 2
        XCTAssertFalse(JMESUtils.compare(lhs, ==, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs!, ==, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs, ==, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs!, ==, rhs!))
    }

    func test_equateDouble_handlesOptionalityCombos() async throws {
        let lhs: Double? = 1.0
        let rhs: Double? = 2.0
        XCTAssertFalse(JMESUtils.compare(lhs, ==, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs!, ==, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs, ==, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs!, ==, rhs!))
    }

    func test_equateString_handlesOptionalityCombos() async throws {
        let lhs: String? = "a"
        let rhs: String? = "b"
        XCTAssertFalse(JMESUtils.compare(lhs, ==, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs!, ==, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs, ==, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs!, ==, rhs!))
        XCTAssertTrue(JMESUtils.compare(lhs, !=, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs!, !=, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs, !=, rhs!))
        XCTAssertTrue(JMESUtils.compare(lhs!, !=, rhs!))
    }

    func test_equateBool_handlesOptionalityCombos() async throws {
        let lhs: Bool? = true
        let rhs: Bool? = false
        XCTAssertFalse(JMESUtils.compare(lhs, ==, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs!, ==, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs, ==, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs!, ==, rhs!))
        XCTAssertTrue(JMESUtils.compare(lhs, !=, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs!, !=, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs, !=, rhs!))
        XCTAssertTrue(JMESUtils.compare(lhs!, !=, rhs!))
    }

    func test_equateIntToDouble_handlesOptionalityCombos() async throws {
        let lhs: Int? = 1
        let rhs: Double? = 2.0
        XCTAssertFalse(JMESUtils.compare(lhs, ==, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs!, ==, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs, ==, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs!, ==, rhs!))
    }

    func test_equateStringToRawRepresentable_handlesOptionalityCombos() async throws {
        let lhs: String? = "a"
        let rhs: Stringed? = Stringed(rawValue: "b")
        XCTAssertFalse(JMESUtils.compare(lhs, ==, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs!, ==, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs, ==, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs!, ==, rhs!))
        XCTAssertTrue(JMESUtils.compare(lhs, !=, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs!, !=, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs, !=, rhs!))
        XCTAssertTrue(JMESUtils.compare(lhs!, !=, rhs!))
    }

    // MARK: - Comparable

    func test_compareInt_handlesOptionalityCombos() async throws {
        let lhs: Int? = 1
        let rhs: Int? = 2
        XCTAssertTrue(JMESUtils.compare(lhs, <, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs!, <, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs, <, rhs!))
        XCTAssertTrue(JMESUtils.compare(lhs!, <, rhs!))
        XCTAssertTrue(JMESUtils.compare(lhs, <=, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs!, <=, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs, <=, rhs!))
        XCTAssertTrue(JMESUtils.compare(lhs!, <=, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs, >, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs!, >, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs, >, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs!, >, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs, >=, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs!, >=, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs, >=, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs!, >=, rhs!))
    }

    func test_compareDouble_handlesOptionalityCombos() async throws {
        let lhs: Double? = 1.0
        let rhs: Double? = 2.0
        XCTAssertTrue(JMESUtils.compare(lhs, <, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs!, <, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs, <, rhs!))
        XCTAssertTrue(JMESUtils.compare(lhs!, <, rhs!))
        XCTAssertTrue(JMESUtils.compare(lhs, <=, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs!, <=, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs, <=, rhs!))
        XCTAssertTrue(JMESUtils.compare(lhs!, <=, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs, >, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs!, >, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs, >, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs!, >, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs, >=, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs!, >=, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs, >=, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs!, >=, rhs!))
    }

    func test_compareIntToDouble_handlesOptionalityCombos() async throws {
        let lhs: Int? = 1
        let rhs: Double? = 2.0
        XCTAssertTrue(JMESUtils.compare(lhs, <, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs!, <, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs, <, rhs!))
        XCTAssertTrue(JMESUtils.compare(lhs!, <, rhs!))
        XCTAssertTrue(JMESUtils.compare(lhs, <=, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs!, <=, rhs))
        XCTAssertTrue(JMESUtils.compare(lhs, <=, rhs!))
        XCTAssertTrue(JMESUtils.compare(lhs!, <=, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs, >, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs!, >, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs, >, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs!, >, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs, >=, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs!, >=, rhs))
        XCTAssertFalse(JMESUtils.compare(lhs, >=, rhs!))
        XCTAssertFalse(JMESUtils.compare(lhs!, >=, rhs!))
    }
}

// Used for tests of Equatable between String and RawRepresentable.
fileprivate struct Stringed: RawRepresentable {
    typealias RawValue = String

    let rawValue: String

    init?(rawValue: String) {
        self.rawValue = rawValue
    }
}
