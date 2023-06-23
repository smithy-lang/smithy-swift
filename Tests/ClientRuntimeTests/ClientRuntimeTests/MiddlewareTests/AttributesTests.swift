//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import ClientRuntime

class AttributesTests: XCTestCase {
    let intKey = AttributeKey<Int>(name: "My Integer")

    func test_setAndGet_setsAValueThenGetsIt() {
        var subject = Attributes()

        subject.set(key: intKey, value: 4)

        XCTAssertEqual(subject.get(key: intKey), 4)
    }

    func test_contains_doesNotContainUnsetKey() {
        let subject = Attributes()

        XCTAssertFalse(subject.contains(key: intKey))
    }

    func test_contains_doesContainSetKey() {
        var subject = Attributes()

        subject.set(key: intKey, value: 0)

        XCTAssertTrue(subject.contains(key: intKey))
    }

    func test_remove_removesAPreviouslySetKey() {
        var subject = Attributes()
        subject.set(key: intKey, value: 0)

        subject.remove(key: intKey)

        XCTAssertNil(subject.get(key: intKey))
    }
}
