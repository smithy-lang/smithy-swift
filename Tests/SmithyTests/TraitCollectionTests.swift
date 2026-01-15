//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Smithy

final class TraitCollectionTests: XCTestCase {

    func test_adding_mergesTraits() async throws {
        let original: TraitCollection = [InputTrait()]
        let new: TraitCollection = [OutputTrait()]
        let combined = original.adding(new)

        XCTAssertEqual(combined, [InputTrait(), OutputTrait()])
    }

    func test_add_addsATrait() async throws {
        var subject: TraitCollection = [InputTrait()]
        subject.add(OutputTrait())

        XCTAssert(subject.hasTrait(InputTrait.self))
        XCTAssert(subject.hasTrait(OutputTrait.self))
    }
}
