//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Smithy

class ShapeIDTests: XCTestCase {

    func test_init_createsShapeIDWithNamespace() throws {
        let subject = try ShapeID("smithy.test#TestName$TestMember")
        XCTAssertEqual(subject.namespace, "smithy.test")
    }

    func test_init_createsShapeIDWithName() throws {
        let subject = try ShapeID("smithy.test#TestName$TestMember")
        XCTAssertEqual(subject.name, "TestName")
    }

    func test_init_createsShapeIDWithMember() throws {
        let subject = try ShapeID("smithy.test#TestName$TestMember")
        XCTAssertEqual(subject.member, "TestMember")
    }

    func test_init_createsShapeIDWithoutMember() throws {
        let subject = try ShapeID("smithy.test#TestName")
        XCTAssertNil(subject.member)
    }
}
