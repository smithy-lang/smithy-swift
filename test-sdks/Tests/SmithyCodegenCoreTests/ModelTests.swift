//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde) import class Smithy.DefaultTrait
@_spi(SchemaBasedSerde) @testable import SmithyCodegenCore
import XCTest

final class ModelTests: XCTestCase {

    // A trait type registered under a Shape ID that is already used by a builtin trait type
    // must cause model creation to throw, rather than silently colliding or trapping.
    func test_init_throwsWhenAdditionalTraitTypeDuplicatesABuiltinTraitID() throws {
        let astModel = try Self.emptyASTModel()
        XCTAssertThrowsError(
            // DefaultTrait is already a builtin runtime trait, so re-registering it is a duplicate.
            try Model(astModel: astModel, additionalTraitTypes: [DefaultTrait.self])
        ) { error in
            XCTAssertTrue(error is ModelError)
        }
    }

    // Registering only the builtin trait types (no additions) is not a duplicate and must succeed.
    func test_init_succeedsWithNoAdditionalTraitTypes() throws {
        let astModel = try Self.emptyASTModel()
        XCTAssertNoThrow(try Model(astModel: astModel, additionalTraitTypes: []))
    }

    private static func emptyASTModel() throws -> ASTModel {
        let json = Data(#"{ "smithy": "2.0", "shapes": {} }"#.utf8)
        return try JSONDecoder().decode(ASTModel.self, from: json)
    }
}
