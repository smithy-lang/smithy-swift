//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Testing
import Foundation
import struct Smithy.URIQueryItem
import SmithyHTTPAPI
@testable import SmithyTestUtil

@Suite
struct HTTPRequestProtocolTestSuiteTests: HTTPRequestProtocolTestSuite {

    private func request(queryItems: [URIQueryItem], body: Data? = nil) -> HTTPRequest {
        let endpoint = Endpoint(host: "example.com", path: "/path", queryItems: queryItems, headers: Headers())
        return HTTPRequest(method: .get, endpoint: endpoint, body: body.map { .data($0) } ?? .noStream)
    }

    // MARK: - Query params

    @Test
    func queryParamValueMayContainEqualsSign() {
        // Only the first `=` separates the name from the value.
        #expect(HTTPRequestTestSupport.queryItem("token=a=b") == URIQueryItem(name: "token", value: "a=b"))
        #expect(HTTPRequestTestSupport.queryItem("token=") == URIQueryItem(name: "token", value: ""))
        #expect(HTTPRequestTestSupport.queryItem("token") == URIQueryItem(name: "token", value: nil))
    }

    @Test
    func queryParamIsMatchedInItsSerializedForm() async throws {
        let actual = request(queryItems: [URIQueryItem(name: "token", value: "YQ==")])
        try await assertRequest(actual, queryParams: ["token=YQ%3D%3D"])
    }

    @Test
    func requiredQueryParamMatchesByName() async throws {
        let actual = request(queryItems: [URIQueryItem(name: "foo", value: "bar")])
        try await assertRequest(actual, requiredQueryParams: ["foo"])
    }

    @Test
    func requiredQueryParamFailsWhenAbsent() async throws {
        let actual = request(queryItems: [])
        await withKnownIssue {
            try await assertRequest(actual, requiredQueryParams: ["foo"])
        }
    }

    @Test
    func forbiddenQueryParamFailsWhenPresentWithAValue() async throws {
        let actual = request(queryItems: [URIQueryItem(name: "foo", value: "bar")])
        await withKnownIssue {
            try await assertRequest(actual, forbiddenQueryParams: ["foo"])
        }
    }

    @Test
    func forbiddenQueryParamPassesWhenAbsent() async throws {
        let actual = request(queryItems: [URIQueryItem(name: "other", value: "bar")])
        try await assertRequest(actual, forbiddenQueryParams: ["foo"])
    }

    // MARK: - Other expectations

    @Test
    func unspecifiedExpectationsAreNotChecked() async throws {
        let actual = request(queryItems: [URIQueryItem(name: "foo", value: "bar")])
        try await assertRequest(actual)
    }

    @Test
    func mismatchedMethodAndPathAreReported() async throws {
        let actual = request(queryItems: [])
        await withKnownIssue {
            try await assertRequest(actual, method: .post, path: "/other")
        }
    }

    @Test
    func bodyIsComparedInTheFormatOfItsMediaType() async throws {
        let actual = request(queryItems: [], body: Data(#"{"a": 1, "b": 2}"#.utf8))
        try await assertRequest(actual, body: Data(#"{"b":2,"a":1}"#.utf8), bodyMediaType: "application/json")
        await withKnownIssue {
            try await assertRequest(actual, body: Data(#"{"b":2,"a":1}"#.utf8), bodyMediaType: "text/plain")
        }
    }

    // MARK: - captureRequest

    @Test
    func captureRequestThrowsHarnessErrorWhenNoRequestIsSent() async throws {
        await #expect(throws: SmithyTestUtilError.self) {
            _ = try await captureRequest { 1 }
        }
    }

    @Test
    func mediaTypesMapToBodyContentTypes() {
        #expect(HTTPBodyContentType(mediaType: "application/json") == .json)
        #expect(HTTPBodyContentType(mediaType: "application/x-amz-json-1.0") == .json)
        #expect(HTTPBodyContentType(mediaType: "application/cbor") == .cbor)
        #expect(HTTPBodyContentType(mediaType: "text/xml") == .xml)
        #expect(HTTPBodyContentType(mediaType: "application/x-www-form-urlencoded") == .formURL)
        #expect(HTTPBodyContentType(mediaType: "application/octet-stream") == nil)
        #expect(HTTPBodyContentType(mediaType: nil) == nil)
    }
}
