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

    func test_init_createsTraitCollectionWithListOfTraits() throws {
        let subject: TraitCollection = [
            InputTrait(),
            OutputTrait(),
            DefaultTrait("abc"),
        ]

        XCTAssertEqual(subject, [DefaultTrait("abc"), InputTrait(), OutputTrait()])
    }

    func test_init_createsTraitCollectionWithShapeIDToNodeMapAndListOfTraitTypes() throws {
        let subject = try TraitCollection(traitDict: [
            InputTrait.id: [:],
            OutputTrait.id: [:],
            DefaultTrait.id: "abc",
        ], traitTypes: [
            DefaultTrait.self,
            OutputTrait.self,
            InputTrait.self,
        ])

        XCTAssertEqual(subject, [DefaultTrait("abc"), InputTrait(), OutputTrait()])
    }

    func test_adding_mergesTraits() throws {
        let original: TraitCollection = [InputTrait()]
        let new: TraitCollection = [OutputTrait()]
        let combined = original.adding(new)

        XCTAssertEqual(combined, [InputTrait(), OutputTrait()])
    }
}
