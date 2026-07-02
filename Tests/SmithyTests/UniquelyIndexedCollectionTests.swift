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

final class UniquelyIndexedCollectionTests: XCTestCase {

    func test_init_initsWithEmptyElements() {
        let subject = UniquelyIndexedCollection([])

        XCTAssertEqual(subject.allElements.count, 0)
    }

    func test_init_initsWithElements() {
        let subject = UniquelyIndexedCollection([InputTrait(), OutputTrait(), DefaultTrait(789.0)])

        XCTAssertEqual(subject.allElements.count, 3)
    }

    func test_get_getsElementByType() {
        let subject = UniquelyIndexedCollection([InputTrait(), OutputTrait(), DefaultTrait(789.0)])

        XCTAssertEqual(subject.get(DefaultTrait.self), DefaultTrait(789.0))
    }
}
