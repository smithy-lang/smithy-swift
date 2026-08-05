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

    func test_set_replacesAPreviouslyStoredElement() {
        let subject = UniquelyIndexedMutableCollection([DefaultTrait(123.0)])
        subject.set(DefaultTrait(456.0))
        XCTAssertEqual(subject.get(DefaultTrait.self), DefaultTrait(456.0))
        XCTAssertEqual(subject.count, 1)
    }

    func test_set_growsStorageForATypeWithAHigherIndexThanStorageCount() {
        // Storage starts empty, so setting any trait must grow storage to fit its unique index.
        // DefaultTrait's index is assigned at runtime by the shared counter, so this exercises
        // the growth path without depending on a specific index value.
        let subject = UniquelyIndexedMutableCollection([])
        XCTAssertTrue(subject.isEmpty)

        subject.set(DefaultTrait(789.0))

        XCTAssertEqual(subject.get(DefaultTrait.self), DefaultTrait(789.0))
        XCTAssertEqual(subject.count, 1)
    }

    func test_get_returnsNilForATypeNeverStored() {
        let subject = UniquelyIndexedMutableCollection([DefaultTrait(789.0)])

        XCTAssertNil(subject.get(InputTrait.self))
    }

    func test_clear_isANoOpForATypeNeverStored() {
        let subject = UniquelyIndexedMutableCollection([])

        subject.clear(DefaultTrait.self)

        XCTAssertTrue(subject.isEmpty)
    }

    // MARK: - Concurrency tests

    func test_concurrentGetAndSet_isThreadSafeAndPreservesValues() {
        // The whole justification for this type is thread safety, so hammer it from many
        // threads at once.  Run under the thread sanitizer to detect races on `_storage`.
        let subject = UniquelyIndexedMutableCollection([])
        subject.set(DefaultTrait(1.0))

        DispatchQueue.concurrentPerform(iterations: 500) { iteration in
            if iteration % 2 == 0 {
                subject.set(DefaultTrait(Double(iteration)))
            } else {
                // A stored value must never read back as nil or as a different type.
                XCTAssertNotNil(subject.get(DefaultTrait.self))
                XCTAssertNil(subject.get(InputTrait.self))
            }
        }

        XCTAssertNotNil(subject.get(DefaultTrait.self))
        XCTAssertEqual(subject.count, 1)
    }

    func test_concurrentSetOfDistinctTypes_storesEveryType() {
        // Concurrent sets of different types each grow storage; all must survive.
        let subject = UniquelyIndexedMutableCollection([])

        DispatchQueue.concurrentPerform(iterations: 100) { iteration in
            switch iteration % 3 {
            case 0: subject.set(InputTrait())
            case 1: subject.set(OutputTrait())
            default: subject.set(DefaultTrait(789.0))
            }
        }

        XCTAssertNotNil(subject.get(InputTrait.self))
        XCTAssertNotNil(subject.get(OutputTrait.self))
        XCTAssertEqual(subject.get(DefaultTrait.self), DefaultTrait(789.0))
        XCTAssertEqual(subject.count, 3)
    }
}
