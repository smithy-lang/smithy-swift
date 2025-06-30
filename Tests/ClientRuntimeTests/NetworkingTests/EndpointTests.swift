//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI
import Foundation
import XCTest
@testable import ClientRuntime

class EndpointTests: XCTestCase {
    let url = URL(string: "https://xctest.amazonaws.com?abc=def&ghi=jkl&mno=pqr")!

    func test_queryItems_setsQueryItemsFromURLInOrder() throws {
        let endpoint = try Endpoint(url: url)
        let expectedQueryItems = [
            URIQueryItem(name: "abc", value: "def"),
            URIQueryItem(name: "ghi", value: "jkl"),
            URIQueryItem(name: "mno", value: "pqr")
        ]
        XCTAssertEqual(endpoint.uri.queryItems, expectedQueryItems)
    }

    func test_hashableAndEquatable_hashesMatchWhenURLQueryItemsAreEqual() throws {
        let endpoint1 = try Endpoint(url: url)
        let endpoint2 = try Endpoint(url: url)
        XCTAssertEqual(endpoint1, endpoint2)
    }

    func test_path_percentEncodedInput() throws {
        let endpoint = Endpoint(
            host: "xctest.amazonaws.com",
            path: "/abc%2Bdef",
            protocolType: .https
        )
        let foundationURL = try XCTUnwrap(endpoint.uri.url)
        let absoluteString = foundationURL.absoluteString
        XCTAssertEqual(absoluteString, "https://xctest.amazonaws.com:443/abc%2Bdef")
    }

    func test_path_unencodedInput() throws {
        let endpoint = Endpoint(
            host: "xctest.amazonaws.com",
            path: "/abc+def",
            protocolType: .https
        )
        let foundationURL = try XCTUnwrap(endpoint.uri.url)
        let absoluteString = foundationURL.absoluteString
        XCTAssertEqual(absoluteString, "https://xctest.amazonaws.com:443/abc+def")
    }
}
