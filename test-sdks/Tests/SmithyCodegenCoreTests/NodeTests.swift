//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Smithy
@testable import SmithyCodegenCore

final class NodeTests: XCTestCase {

    func test_objectRendering_rendersSortedAndDeterministically() throws {
        let objectNode: Node = [
            "f": 1,
            "a": 2,
            "e": 3,
            "b": 4,
            "d": 5,
            "c": 6,
        ]

        // The above node should render like this: in order of sorted keys
        let expected = #"["a": 2.0, "b": 4.0, "c": 6.0, "d": 5.0, "e": 3.0, "f": 1.0]"#
        XCTAssertEqual(objectNode.rendered, expected)
    }
}
