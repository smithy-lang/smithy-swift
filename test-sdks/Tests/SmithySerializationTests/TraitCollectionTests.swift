//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SchemaBasedSerde)
import Smithy
//@_spi(SchemaBasedSerde)
//import SmithyCodegenCore

final class TraitCollectionTests: XCTestCase {

    func test_hasTrait_returnsCorrectly() throws {
        let subject = try TraitCollection(traitMap: [RequiredTrait.id: [:]])
        XCTAssert(subject.hasTrait(RequiredTrait.self))
    }

    func test_adding_mergesTraits() throws {
        let original: TraitCollection = [InputTrait()]
        let new: TraitCollection = [OutputTrait()]
        let combined = original.adding(new)
        XCTAssert(combined.hasTrait(InputTrait.self))
        XCTAssert(combined.hasTrait(OutputTrait.self))
    }
}
