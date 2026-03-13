//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Smithy

class ShapeIDTests: XCTestCase {

    func test_description_noMember() {
        let subject = ShapeID("smithy.test", "TestShape")
        XCTAssertEqual(subject.description, "smithy.test#TestShape")
    }

    func test_description_withMember() {
        let subject = ShapeID("smithy.test", "TestShape", "TestMember")
        XCTAssertEqual(subject.description, "smithy.test#TestShape$TestMember")
    }
}
