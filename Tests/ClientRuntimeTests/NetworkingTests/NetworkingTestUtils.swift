/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation
import ClientRuntime
import XCTest

class NetworkingTestUtils: XCTestCase {

    var mockHttpDataRequest: SdkHttpRequest!
    var mockHttpStreamRequest: SdkHttpRequest!
    var expectedMockRequestURL: URL!
    var expectedMockRequestData: Data!

    override func setUp() {
        super.setUp()
        expectedMockRequestURL = URL(string: "https://myapi.host.com/path/to/endpoint?qualifier=qualifier-value")!
        let mockRequestBody = "{\"parameter\": \"value\"}"
        expectedMockRequestData = mockRequestBody.data(using: .utf8)
        setMockHttpDataRequest()
        setMockHttpStreamRequest()
    }

    /*
     Create a mock HttpRequest with valid data payload
     */
    func setMockHttpDataRequest() {
        let headers = Headers(["header-item-name": "header-item-value"])
        let endpoint = getMockEndpoint(headers: headers)

        let httpBody = ByteStream.data(expectedMockRequestData)
        mockHttpDataRequest = SdkHttpRequest(method: .get, endpoint: endpoint, body: httpBody)
    }

    /*
     Create a mock HttpRequest with valid InputStream
     */
    func setMockHttpStreamRequest() {
        let headers = Headers(["header-item-name": "header-item-value"])
        let endpoint = getMockEndpoint(headers: headers)

        let httpBody = ByteStream.data(expectedMockRequestData)
        mockHttpStreamRequest = SdkHttpRequest(method: .get, endpoint: endpoint, body: httpBody)
    }

    func getMockEndpoint(headers: Headers) -> Endpoint {
        let path = "/path/to/endpoint"
        let host = "myapi.host.com"
        var queryItems: [SDKURLQueryItem] = []
        let endpoint: Endpoint!

        queryItems.append(SDKURLQueryItem(name: "qualifier", value: "qualifier-value"))
        endpoint = Endpoint(host: host, path: path, queryItems: queryItems, headers: headers)
        return endpoint
    }

    func testHttpStatusCodeDescriptionWorks() {
        let httpStatusCode = HttpStatusCode.ok
        let httpStatusCodeDescription = httpStatusCode.description

        XCTAssertNotNil(httpStatusCodeDescription)
    }
}
