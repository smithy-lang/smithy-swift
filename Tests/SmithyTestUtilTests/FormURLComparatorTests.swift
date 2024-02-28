//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import SmithyTestUtil

class FormURLComparatorTests: XCTestCase {

    func test_compare_sameDataIsEqual() {
        let a = Data("Param1=ABC&Param2=DEF".utf8)
        let b = Data("Param1=ABC&Param2=DEF".utf8)
        XCTAssertTrue(FormURLComparator.formURLData(a, isEqualTo: b))
    }

    func test_compare_reversedOrderItemsAreEqual() {
        let a = Data("Param1=ABC&Param2=DEF".utf8)
        let b = Data("Param2=DEF&Param1=ABC".utf8)
        XCTAssertTrue(FormURLComparator.formURLData(a, isEqualTo: b))
    }

    func test_compare_reversedValuesAreNotEqual() {
        let a = Data("Param1=ABC&Param2=DEF".utf8)
        let b = Data("Param2=ABC&Param1=DEF".utf8)
        XCTAssertFalse(FormURLComparator.formURLData(a, isEqualTo: b))
    }

    func test_compare() {
        let a = Data("""
            Action=SimpleInputParams&Version=2020-01-08&FloatValue=Infinity&Boo=Infinity
            """.utf8)
        let b = Data("Action=SimpleInputParams&Version=2020-01-08&FloatValue=Infinity&Boo=Infinity".utf8)
        XCTAssertTrue(FormURLComparator.formURLData(a, isEqualTo: b))
    }
}
