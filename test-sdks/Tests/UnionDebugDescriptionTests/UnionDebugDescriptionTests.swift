//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import struct UnionDebugDescriptionTestSDK.GetUnionsOutput
import enum UnionDebugDescriptionTestSDK.UnionDebugDescriptionClientTypes

/// Tests the debugDescription generated for unions on a service that does not use schema-based serialization.
final class UnionDebugDescriptionTests: XCTestCase {
    typealias Types = UnionDebugDescriptionClientTypes

    private let secret = "super-important-secret"

    func test_sensitiveVariants_areRedacted() {
        let unions: [Types.SensitiveVariantUnion] = [
            .secret(secret),
            .secretlist([secret]),
            .secretmap(["key": secret]),
        ]
        for union in unions {
            let description = String(describing: union)
            XCTAssertFalse(description.contains(secret), description)
            XCTAssertTrue(description.contains("CONTENT_REDACTED"), description)
        }
    }

    func test_nonSensitiveVariant_printsItsValue() {
        let description = String(describing: Types.SensitiveVariantUnion.plain("visible-value"))
        XCTAssertTrue(description.contains("visible-value"), description)
    }

    func test_variantHoldingStruct_keepsTheStructsRedaction() {
        let union = Types.SensitiveVariantUnion.withstruct(.init(name: "visible-name", password: secret))
        let description = String(describing: union)
        XCTAssertFalse(description.contains(secret), description)
        XCTAssertTrue(description.contains("visible-name"), description)
    }

    func test_sensitiveUnion_isFullyRedacted() {
        for union: Types.SensitiveUnion in [.a("visible-value"), .b(42)] {
            let description = String(describing: union)
            XCTAssertEqual(description, "CONTENT_REDACTED")
        }
    }

    func test_unionsNestedInListMapAndStruct_areRedacted() {
        let output = GetUnionsOutput(
            holder: .init(nested: .secret(secret)),
            unionList: [.secret(secret), .plain("visible-value")],
            unionMap: ["key": .secret(secret)]
        )
        let description = String(describing: output)
        XCTAssertFalse(description.contains(secret), description)
        XCTAssertTrue(description.contains("visible-value"), description)
    }
}
