//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import func SmithyHTTPAPI.getQueryItems
import Foundation
import XCTest
@testable import ClientRuntime

class URITests: XCTestCase {
    let url = URL(string: "https://xctest.amazonaws.com?abc=def&ghi=jkl&mno=pqr")!

    let unencodedReservedCharacters: String = "!$&'()*+,;="

    let encodedReservedCharacters: String = "%21%24%26%27%28%29%2A%2B%2C%3B%3D"

    func test_queryItems_setsQueryItemsFromURLInOrder() throws {
        let uri = URIBuilder()
            .withScheme(URIScheme(rawValue: url.scheme!)!)
            .withPath(url.path)
            .withHost(url.host!)
            .withPort(url.port)
            .withQueryItems(getQueryItems(url: url)!)
            .build()

        let expectedQueryItems = [
            URIQueryItem(name: "abc", value: "def"),
            URIQueryItem(name: "ghi", value: "jkl"),
            URIQueryItem(name: "mno", value: "pqr")
        ]
        XCTAssertEqual(uri.queryItems, expectedQueryItems)
        XCTAssertEqual(uri.queryString, "abc=def&ghi=jkl&mno=pqr")
    }

    func test_hashableAndEquatable_hashesMatch() throws {
        let uri1 = URIBuilder()
            .withScheme(URIScheme(rawValue: url.scheme!)!)
            .withPath(url.path)
            .withHost(url.host!)
            .withPort(url.port)
            .withQueryItems(getQueryItems(url: url)!)
            .build()
        let uri2 = URIBuilder()
            .withScheme(URIScheme(rawValue: url.scheme!)!)
            .withPath(url.path)
            .withHost(url.host!)
            .withPort(url.port)
            .withQueryItems(getQueryItems(url: url)!)
            .build()
        XCTAssertEqual(uri1, uri2)
        XCTAssertEqual(uri1.hashValue, uri2.hashValue)
    }

    func test_path_percentEncodedInput() throws {
        let uri = URIBuilder()
            .withScheme(URIScheme(rawValue: url.scheme!)!)
            .withPath(url.path)
            .withHost(url.host!)
            .withPort(443)
            .withQueryItems(getQueryItems(url: url)!)
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

    func test_modifyURI() throws {
        var uri = URIBuilder()
            .withScheme(URIScheme(rawValue: url.scheme!)!)
            .withPath(url.path)
            .withHost(url.host!)
            .withPort(url.port)
            .withQueryItems(getQueryItems(url: url)!)
            .build()

        uri = uri.toBuilder()
            .withPath("/x%2Dy%2Dz")
            .withHost("%2Bxctest2.com")
            .appendQueryItem(URIQueryItem(name: "test", value: "1%2B2"))
            .withFragment("fragment%21")
            .withUsername("dan%21")
            .withPassword("%24008")
            .build()

        XCTAssertEqual(uri.url?.absoluteString,
           "https://dan%21:%24008@+xctest2.com/x%2Dy%2Dz?abc=def&ghi=jkl&mno=pqr&test=1%2B2#fragment%21")
    }

    func test_host_unencodedReservedCharacters() throws {
        let uri = URIBuilder()
            .withScheme(.https)
            .withHost("xctest.\(unencodedReservedCharacters).com")
            .withPath("/")
            .build()
        XCTAssertEqual(uri.url?.absoluteString, "https://xctest.!$&\'()*+,;=.com/")
    }

    func test_host_encodedReservedCharacters() throws {
        let uri = URIBuilder()
            .withScheme(.https)
            .withHost("xctest.\(encodedReservedCharacters).com")
            .withPath("/")
            .build()
        XCTAssertEqual(uri.url?.absoluteString, "https://xctest.!$&\'()*+,;=.com/")
    }

    func test_host_encodedAndUnencodedReservedCharacters() throws {
        let uri = URIBuilder()
            .withScheme(.https)
            .withHost("xctest.\(unencodedReservedCharacters)\(encodedReservedCharacters).com")
            .withPath("/")
            .build()
        XCTAssertEqual(uri.url?.absoluteString, "https://xctest.!$&\'()*+,;=!$&\'()*+,;=.com/")
    }

    func test_path_unencodedReservedCharacters() throws {
        let uri = URIBuilder()
            .withScheme(.https)
            .withHost("xctest.com")
            .withPath("/:@\(unencodedReservedCharacters)")
            .build()
        XCTAssertEqual(uri.url?.absoluteString, "https://xctest.com/:@!$&\'()*+,%3B=")
    }

    func test_path_encodedReservedCharacters() throws {
        let uri = URIBuilder()
            .withScheme(.https)
            .withHost("xctest.com")
            .withPath("/\(encodedReservedCharacters)")
            .build()
        XCTAssertEqual(uri.url?.absoluteString, "https://xctest.com/%21%24%26%27%28%29%2A%2B%2C%3B%3D")
    }

    func test_path_encodedAndUnencodedReservedCharacters() throws {
        let uri = URIBuilder()
            .withScheme(.https)
            .withHost("xctest.com")
            .withPath("/:@\(unencodedReservedCharacters)\(encodedReservedCharacters)")
            .build()
        XCTAssertEqual(uri.url?.absoluteString, "https://xctest.com/:@!$&\'()*+,%3B=%21%24%26%27%28%29%2A%2B%2C%3B%3D")
    }

    func test_query_unencodedReservedCharacters() throws {
        let uri = URIBuilder()
            .withScheme(.https)
            .withHost("xctest.com")
            .withPath("/")
            .withQueryItems([
                URIQueryItem(
                    name: "key:@\(unencodedReservedCharacters))",
                    value: "value:@\(unencodedReservedCharacters)"
                ),
            ])
            .build()
        XCTAssertEqual(uri.url?.absoluteString, "https://xctest.com/?key:@!$%26\'()*+,;%3D)=value:@!$%26\'()*+,;%3D")
    }

    func test_query_encodedReservedCharacters() throws {
        let uri = URIBuilder()
            .withScheme(.https)
            .withHost("xctest.com")
            .withPath("/")
            .withQueryItems([
                URIQueryItem(
                    name: "key:@\(encodedReservedCharacters))",
                    value: "value:@\(encodedReservedCharacters)"
                ),
            ])
            .build()
        XCTAssertEqual(uri.url?.absoluteString,
            "https://xctest.com/?key:@%21%24%26%27%28%29%2A%2B%2C%3B%3D)=value:@%21%24%26%27%28%29%2A%2B%2C%3B%3D")
    }

    func test_query_unencodedAndEncodedReservedCharacters() throws {
        let uri = URIBuilder()
            .withScheme(.https)
            .withHost("xctest.com")
            .withPath("/")
            .withQueryItems([
                URIQueryItem(
                    name: "key:@\(encodedReservedCharacters))",
                    value: "value:@\(unencodedReservedCharacters)"
                ),
            ])
            .build()
        XCTAssertEqual(uri.url?.absoluteString,
            "https://xctest.com/?key:@%21%24%26%27%28%29%2A%2B%2C%3B%3D)=value:@!$&\'()*+,;=")
    }
}
