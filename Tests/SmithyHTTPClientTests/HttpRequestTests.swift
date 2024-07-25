/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Smithy
import SmithyHTTPAPI
import SmithyHTTPClient
import XCTest
import AwsCommonRuntimeKit
import SmithyTestUtil
import struct Foundation.URLQueryItem
@testable import ClientRuntime
// In Linux, Foundation.URLRequest is moved to FoundationNetworking.
#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import struct Foundation.URLRequest
#endif

class HttpRequestTests: NetworkingTestUtils {

    override func setUp() {
        super.setUp()
    }

    func testSdkHttpRequestToHttpRequest() throws {
        let headers = Headers(["header-item-name": "header-item-value"])
        let endpoint = Endpoint(host: "host.com", path: "/", headers: headers)

        let httpBody = ByteStream.data(expectedMockRequestData)
        let mockHttpRequest = HTTPRequest(method: .get, endpoint: endpoint, body: httpBody)
        mockHttpRequest.withHeader(name: "foo", value: "bar")
        let httpRequest = try mockHttpRequest.toHttpRequest()

        XCTAssertNotNil(httpRequest)
        let headersFromRequest = httpRequest.getHeaders()
        XCTAssertNotNil(headers)

        // Check headers
        var additionalHeaderFound = false
        for index in 0...(httpRequest.headerCount - 1) {
            let header1 = headersFromRequest[index]
            let header2 = mockHttpRequest.headers.headers[index]

            // Check for additional header
            if header1.name == "foo" {
                XCTAssertEqual(header1.value, "bar")
                additionalHeaderFound = true
            }

            XCTAssertEqual(header1.name, header2.name)
            XCTAssertEqual(header1.value, header2.value.joined(separator: ","))
        }

        XCTAssertTrue(additionalHeaderFound, "Additional header 'foo' not found in httpRequest")
        XCTAssertEqual(httpRequest.method, "GET")

        if let bodyLength = try httpRequest.body?.length() {
            XCTAssertEqual(Int(bodyLength), expectedMockRequestData.count)
        }
    }

    func testSdkHttpRequestToURLRequest() async throws {
        let headers = Headers(["Testname-1": "testvalue-1", "Testname-2": "testvalue-2"])
        let endpoint = Endpoint(host: "host.com", path: "/", headers: headers)

        let httpBody = ByteStream.data(expectedMockRequestData)
        let mockHttpRequest = HTTPRequest(method: .get, endpoint: endpoint, body: httpBody)
        let urlRequest = try await HTTPRequest.makeURLRequest(from: mockHttpRequest)

        XCTAssertNotNil(urlRequest)
        guard let headersFromRequest = urlRequest.allHTTPHeaderFields else {
            XCTFail("Headers in HTTPRequest were not successfully converted to headers in URLRequest.")
            // Compiler doesn't recognize XCTFail as return / exception thrown
            return
        }

        // Check URLRequest fields
        XCTAssertTrue(headersFromRequest.contains { $0.key == "Testname-1" && $0.value == "testvalue-1" })
        XCTAssertTrue(headersFromRequest.contains { $0.key == "Testname-2" && $0.value == "testvalue-2" })
        let expectedBody = try await httpBody.readData()
        XCTAssertEqual(urlRequest.httpBody, expectedBody)
        XCTAssertEqual(urlRequest.url, endpoint.uri.url)
        XCTAssertEqual(urlRequest.httpMethod, mockHttpRequest.method.rawValue)
    }

    func testCRTHeadersToSdkHeaders() throws {
        let builder = HTTPRequestBuilder()
            .withHeader(name: "Host", value: "amazon.aws.com")
            .withPath("/hello")
            .withHeader(name: "Content-Length", value: "6")
        let httpRequest = try builder.build().toHttpRequest()
        httpRequest.addHeaders(headers: [HTTPHeader(name: "SomeSignedHeader", value: "IAMSIGNED")])
        let headers = builder.convertSignedHeadersToHeaders(crtRequest: httpRequest)
        XCTAssert(headers.headers.count == 3)
        XCTAssert(headers.headers.contains(Header(name: "SomeSignedHeader", value: "IAMSIGNED")))
        XCTAssert(headers.headers.contains(Header(name: "Content-Length", value: "6")))
        XCTAssert(headers.headers.contains(Header(name: "Host", value: "amazon.aws.com")))
    }

    func testSdkPathAndQueryItemsToCRTPathAndQueryItems() throws {
        let queryItem1 = URIQueryItem(name: "foo", value: "bar")
        let queryItem2 = URIQueryItem(name: "quz", value: "baz")
        let builder = HTTPRequestBuilder()
            .withHeader(name: "Host", value: "amazon.aws.com")
            .withPath("/hello")
            .withQueryItem(queryItem1)
            .withQueryItem(queryItem2)
            .withHeader(name: "Content-Length", value: "6")
        let httpRequest = try builder.build().toHttpRequest()
        XCTAssert(httpRequest.path == "/hello?foo=bar&quz=baz")
    }

    func testCRTPathAndQueryItemsToSdkPathAndQueryItems() throws {
        let queryItem1 = URIQueryItem(name: "foo", value: "bar")
        let queryItem2 = URIQueryItem(name: "quz", value: "bar")
        let builder = HTTPRequestBuilder()
            .withHeader(name: "Host", value: "amazon.aws.com")
            .withPath("/hello")
            .withQueryItem(queryItem1)
            .withQueryItem(queryItem2)
            .withHeader(name: "Content-Length", value: "6")

        XCTAssertEqual(builder.queryItems.count, 2)

        let httpRequest = try builder.build().toHttpRequest()
        httpRequest.path = "/hello?foo=bar&quz=bar&signedthing=signed"
        let updatedRequest = builder.update(from: httpRequest, originalRequest: builder.build())

        XCTAssertEqual(updatedRequest.path, "/hello")
        XCTAssertEqual(updatedRequest.queryItems.count, 3)
        XCTAssert(updatedRequest.queryItems.contains(queryItem1))
        XCTAssert(updatedRequest.queryItems.contains(queryItem2))
        XCTAssert(updatedRequest.queryItems.contains(URIQueryItem(name: "signedthing", value: "signed")))
    }

    func testPathInInHttpRequestIsNotAltered() throws {
        let path = "/space%20/colon:/dollar$/tilde~/dash-/underscore_/period."
        let builder = HTTPRequestBuilder()
            .withHeader(name: "Host", value: "xctest.amazon.com")
            .withPath(path)
        let httpRequest = try builder.build().toHttpRequest()
        XCTAssertEqual(httpRequest.path, path)
    }

    func testConversionToUrlRequestFailsWithInvalidEndpoint() {
        // Testing with an invalid endpoint where host is empty,
        // path is empty, and protocolType is nil.
        let endpoint = Endpoint(host: "", path: "")
        XCTAssertNil(endpoint.url, "An invalid endpoint should result in a nil URL.")
    }
}
