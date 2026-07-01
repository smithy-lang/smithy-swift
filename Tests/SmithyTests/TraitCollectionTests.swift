//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SchemaBasedSerde)
import Smithy

final class TraitCollectionTests: XCTestCase {

    func test_init_createsTraitsWithMapOfIDToNode() throws {
        let subject: TraitCollection = [
            InputTrait.id: [:],
            OutputTrait.id: [:],
            DefaultTrait.id: "abc",
        ]
        XCTAssertEqual(subject, [try DefaultTrait(node: "abc"), InputTrait(), OutputTrait()])
    }

    func test_adding_mergesTraits() throws {
        let original: TraitCollection = [InputTrait()]
        let new: TraitCollection = [OutputTrait()]
        let combined = original.adding(new)

        XCTAssertEqual(combined, [InputTrait(), OutputTrait()])
    }
}
