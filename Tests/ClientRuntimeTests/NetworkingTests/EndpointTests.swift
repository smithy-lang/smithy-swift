//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime

class EndpointTests: XCTestCase {
    let url = URL(string: "https://xctest.amazonaws.com?abc=def&ghi=jkl&mno=pqr")!

    func test_queryItems_setsQueryItemsFromURLInOrder() throws {
        let endpoint = try Endpoint(url: url)
        let expectedQueryItems = [
            URLQueryItem(name: "abc", value: "def"),
            URLQueryItem(name: "ghi", value: "jkl"),
            URLQueryItem(name: "mno", value: "pqr")
        ]
        XCTAssertEqual(endpoint.queryItems, expectedQueryItems)
    }

    func test_hashableAndEquatable_hashesMatchWhenURLQueryItemsAreEqual() throws {
        let endpoint1 = try Endpoint(url: url)
        let endpoint2 = try Endpoint(url: url)
        XCTAssertEqual(endpoint1, endpoint2)
        XCTAssertEqual(endpoint1.hashValue, endpoint2.hashValue)
    }
}
