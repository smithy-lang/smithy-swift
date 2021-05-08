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
    
    func testSdkHttpRequestToHttpRequest() {
        let endpoint = Endpoint(host: "host.com", path: "/")
        var headers = Headers()
        
        headers.add(name: "header-item-name", value: "header-item-value")
        
        let httpBody = HttpBody.data(expectedMockRequestData)
        let mockHttpRequest = SdkHttpRequest(method: .get, endpoint: endpoint, headers: headers, body: httpBody)
        let httpRequest = mockHttpRequest.toHttpRequest()
        
        XCTAssertNotNil(httpRequest)
        let headersFromRequest = httpRequest.headers?.getAll()
        XCTAssertNotNil(headers)
        for index in 0...(httpRequest.headerCount - 1) {
            
            let header1 = headersFromRequest![index]
            let header2 = mockHttpRequest.headers.headers[index]
            XCTAssertEqual(header1.name, header2.name)
            XCTAssertEqual(header1.value, header2.value)
        }
        
        XCTAssertEqual(httpRequest.method, "GET")
        
        if let bodyLength = httpRequest.body?.length {
            XCTAssertEqual(Int(bodyLength), expectedMockRequestData.count)
        }
    }
    
    func testCRTHeadersToSdkHeaders() {
        let builder = SdkHttpRequestBuilder()
            .withHeader(name: "Host", value: "amazon.aws.com")
            .withPath("/hello")
            .withHeader(name: "Content-Length", value: "6")
        let httpRequest = builder.build().toHttpRequest()
        let newHeaders = HttpHeaders()
        _ = newHeaders.add(name: "SomeSignedHeader", value: "IAMSIGNED")
        httpRequest.addHeaders(headers: newHeaders)
        let headers = builder.convertSignedHeadersToHeaders(crtRequest: httpRequest)
        XCTAssert(headers.headers.count == 3)
        XCTAssert(headers.headers.contains(Header(name: "SomeSignedHeader", value: "IAMSIGNED")))
        XCTAssert(headers.headers.contains(Header(name: "Content-Length", value: "6")))
        XCTAssert(headers.headers.contains(Header(name: "Host", value: "amazon.aws.com")))
    }
    
    func testSdkPathAndQueryItemsToCRTPathAndQueryItems() {
        let queryItem1 = URLQueryItem(name: "foo", value: "bar")
        let queryItem2 = URLQueryItem(name: "quz", value: "baz")
        let builder = SdkHttpRequestBuilder()
            .withHeader(name: "Host", value: "amazon.aws.com")
            .withPath("/hello")
            .withQueryItem(queryItem1)
            .withQueryItem(queryItem2)
            .withHeader(name: "Content-Length", value: "6")
        let httpRequest = builder.build().toHttpRequest()
        XCTAssert(httpRequest.path == "/hello?foo=bar&quz=baz")
    }
    
    func testCRTPathAndQueryItemsToSdkPathAndQueryItems() {
        let queryItem1 = URLQueryItem(name: "foo", value: "bar")
        let queryItem2 = URLQueryItem(name: "quz", value: "bar")
        let builder = SdkHttpRequestBuilder()
            .withHeader(name: "Host", value: "amazon.aws.com")
            .withPath("/hello")
            .withQueryItem(queryItem1)
            .withQueryItem(queryItem2)
            .withHeader(name: "Content-Length", value: "6")
        
        XCTAssert(builder.queryItems.count == 2)
        
        let httpRequest = builder.build().toHttpRequest()
        httpRequest.path = "/hello?foo=bar&quz=bar&signedthing=signed"
        let updatedRequest = builder.update(from: httpRequest, originalRequest: builder.build())
        
        XCTAssert(updatedRequest.path == "/hello")
        XCTAssert(updatedRequest.queryItems.count == 3)
        XCTAssert(updatedRequest.queryItems.contains(queryItem1))
        XCTAssert(updatedRequest.queryItems.contains(queryItem2))
        XCTAssert(updatedRequest.queryItems.contains(URLQueryItem(name: "signedthing", value: "signed")))
    }
    
    func testConversionToUrlRequestFailsWithInvalidEndpoint() {
        // TODO:: When is the endpoint invalid or endpoint.url nil?
        _ = Endpoint(host: "", path: "", protocolType: nil)
    }
}
