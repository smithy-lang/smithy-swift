//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
@testable
import Smithy
import XCTest

final class UniquelyIndexedMutableCollectionTests: XCTestCase {

    // MARK: - Immutable tests

    func test_init_initsWithEmptyElements() {
        let subject = UniquelyIndexedMutableCollection([])

        XCTAssertEqual(subject.allElements.count, 0)
    }

    func test_init_initsWithElements() {
        let subject = UniquelyIndexedMutableCollection([InputTrait(), OutputTrait(), DefaultTrait(789.0)])

        XCTAssertEqual(subject.allElements.count, 3)
    }

    func test_get_getsElementByType() {
        let subject = UniquelyIndexedMutableCollection([InputTrait(), OutputTrait(), DefaultTrait(789.0)])

        XCTAssertEqual(subject.get(DefaultTrait.self), DefaultTrait(789.0))
    }

    func test_count_countsElements() {
        XCTAssertEqual(UniquelyIndexedMutableCollection([]).count, 0)
        XCTAssertEqual(UniquelyIndexedMutableCollection([InputTrait(), OutputTrait(), DefaultTrait(789.0)]).count, 3)
    }

    func test_isEmpty_isTrueOnlyWhenCollectionHasNoElements() {
        XCTAssertTrue(UniquelyIndexedMutableCollection([]).isEmpty)
        XCTAssertFalse(UniquelyIndexedMutableCollection([InputTrait()]).isEmpty)
    }

    // MARK: - Mutable tests

    func test_set_setsAnElement() {
        let subject = UniquelyIndexedMutableCollection([])
        subject.set(DefaultTrait(567.0))
        XCTAssertEqual(subject.get(DefaultTrait.self), DefaultTrait(567.0))
    }

    func test_clear_clearsAnElement() {
        let subject = UniquelyIndexedMutableCollection([DefaultTrait(567.0)])
        subject.clear(DefaultTrait.self)
        XCTAssertEqual(subject.get(DefaultTrait.self), nil)
    }
}
