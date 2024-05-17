//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime

class URITests: XCTestCase {
    let url = URL(string: "https://xctest.amazonaws.com?abc=def&ghi=jkl&mno=pqr")!

    func test_queryItems_setsQueryItemsFromURLInOrder() throws {
        let uri = URIBuilder()
            .withScheme(Scheme(rawValue: url.scheme!)!)
            .withPath(url.path)
            .withHost(url.host!)
            .withPort(url.port)
            .withQueryItems(url.getQueryItems()!)
            .build()

        let expectedQueryItems = [
            SDKURLQueryItem(name: "abc", value: "def"),
            SDKURLQueryItem(name: "ghi", value: "jkl"),
            SDKURLQueryItem(name: "mno", value: "pqr")
        ]
        XCTAssertEqual(uri.queryItems, expectedQueryItems)
        XCTAssertEqual(uri.queryString, "abc=def&ghi=jkl&mno=pqr")
    }

    func test_hashableAndEquatable_hashesMatch() throws {
        let uri1 = URIBuilder()
            .withScheme(Scheme(rawValue: url.scheme!)!)
            .withPath(url.path)
            .withHost(url.host!)
            .withPort(url.port)
            .withQueryItems(url.getQueryItems()!)
            .build()
        let uri2 = URIBuilder()
            .withScheme(Scheme(rawValue: url.scheme!)!)
            .withPath(url.path)
            .withHost(url.host!)
            .withPort(url.port)
            .withQueryItems(url.getQueryItems()!)
            .build()
        XCTAssertEqual(uri1, uri2)
        XCTAssertEqual(uri1.hashValue, uri2.hashValue)
    }

    func test_path_percentEncodedInput() throws {
        let uri = URIBuilder()
            .withScheme(Scheme(rawValue: url.scheme!)!)
            .withPath(url.path)
            .withHost(url.host!)
            .withPort(443)
            .withQueryItems(url.getQueryItems()!)
            .build()
        XCTAssertEqual(uri.url?.absoluteString, "https://xctest.amazonaws.com:443?abc=def&ghi=jkl&mno=pqr")
    }

    func test_path_unencodedInput() throws {
        let uri = URIBuilder()
            .withScheme(.https)
            .withPath("/abc+def")
            .withHost("xctest.amazonaws.com")
            .withPort(443)
            .build()
        XCTAssertEqual(uri.url?.absoluteString, "https://xctest.amazonaws.com:443/abc+def")
    }
}
