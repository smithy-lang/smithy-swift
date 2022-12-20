/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
import AwsCommonRuntimeKit
import struct Foundation.URLQueryItem
@testable import ClientRuntime

class HttpRequestTests: NetworkingTestUtils {
    
    override func setUp() {
        super.setUp()
    }
    
    func testSdkHttpRequestToHttpRequest() throws {
        let endpoint = Endpoint(host: "host.com", path: "/")
        var headers = Headers()
        
        headers.add(name: "header-item-name", value: "header-item-value")
        
        let httpBody = HttpBody.data(expectedMockRequestData)
        let mockHttpRequest = SdkHttpRequest(method: .get, endpoint: endpoint, headers: headers, body: httpBody)
        let httpRequest = try mockHttpRequest.toHttpRequest()
        
        XCTAssertNotNil(httpRequest)
        let headersFromRequest = httpRequest.getHeaders()
        XCTAssertNotNil(headers)
        for index in 0...(httpRequest.headerCount - 1) {
            
            let header1 = headersFromRequest[index]
            let header2 = mockHttpRequest.headers.headers[index]
            XCTAssertEqual(header1.name, header2.name)
            XCTAssertEqual(header1.value, header2.value.joined(separator: ","))
        }
        
        XCTAssertEqual(httpRequest.method, "GET")
        
        if let bodyLength = try httpRequest.body?.length() {
            XCTAssertEqual(Int(bodyLength), expectedMockRequestData.count)
        }
    }
    
    func testCRTHeadersToSdkHeaders() throws {
        let builder = SdkHttpRequestBuilder()
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
        let queryItem1 = URLQueryItem(name: "foo", value: "bar")
        let queryItem2 = URLQueryItem(name: "quz", value: "baz")
        let builder = SdkHttpRequestBuilder()
            .withHeader(name: "Host", value: "amazon.aws.com")
            .withPath("/hello")
            .withQueryItem(queryItem1)
            .withQueryItem(queryItem2)
            .withHeader(name: "Content-Length", value: "6")
        let httpRequest = try builder.build().toHttpRequest()
        XCTAssert(httpRequest.path == "/hello?foo=bar&quz=baz")
    }
    
    func testCRTPathAndQueryItemsToSdkPathAndQueryItems() throws {
        let queryItem1 = URLQueryItem(name: "foo", value: "bar")
        let queryItem2 = URLQueryItem(name: "quz", value: "bar")
        let builder = SdkHttpRequestBuilder()
            .withHeader(name: "Host", value: "amazon.aws.com")
            .withPath("/hello")
            .withQueryItem(queryItem1)
            .withQueryItem(queryItem2)
            .withHeader(name: "Content-Length", value: "6")
        
        XCTAssert(builder.queryItems.count == 2)
        
        let httpRequest = try builder.build().toHttpRequest()
        httpRequest.path = "/hello?foo=bar&quz=bar&signedthing=signed"
        let updatedRequest = builder.update(from: httpRequest, originalRequest: builder.build())
        
        XCTAssert(updatedRequest.path == "/hello")
        XCTAssert(updatedRequest.queryItems.count == 3)
        XCTAssert(updatedRequest.queryItems.contains(queryItem1))
        XCTAssert(updatedRequest.queryItems.contains(queryItem2))
        XCTAssert(updatedRequest.queryItems.contains(URLQueryItem(name: "signedthing", value: "signed")))
    }

    func testPathInInHttpRequestIsEscapedPerRFC3986() throws {
        let builder = SdkHttpRequestBuilder()
            .withHeader(name: "Host", value: "xctest.amazon.com")
            .withPath("/space /colon:/dollar$/tilde~/dash-/underscore_/period.")
        let httpRequest = try builder.build().toHttpRequest()
        let escapedPath = "/space%20/colon%3A/dollar%24/tilde~/dash-/underscore_/period."
        XCTAssertEqual(httpRequest.path, escapedPath)
    }
    
    func testConversionToUrlRequestFailsWithInvalidEndpoint() {
        // TODO:: When is the endpoint invalid or endpoint.url nil?
        _ = Endpoint(host: "", path: "", protocolType: nil)
    }
}
