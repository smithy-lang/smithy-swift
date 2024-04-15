//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import SmithyJSON

class WriterTests: XCTestCase {

    func test_writesJSON() async throws {
        let writer = Writer(nodeInfo: "")
        try writer["property"].write("potato")
        XCTAssertEqual(String(data: try writer.data(), encoding: .utf8), "{\"property\":\"potato\"}")
    }
}
