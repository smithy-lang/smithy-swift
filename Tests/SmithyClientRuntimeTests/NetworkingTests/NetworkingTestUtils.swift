/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation
import SmithyClientRuntime
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
        let endpoint = getMockEndpoint()
        var headers = Headers()

        headers.add(name: "header-item-name", value: "header-item-value")

        let httpBody = HttpBody.data(expectedMockRequestData)
        mockHttpDataRequest = SdkHttpRequest(method: .get, endpoint: endpoint, headers: headers, body: httpBody)
    }

    /*
     Create a mock HttpRequest with valid InputStream
     */
    func setMockHttpStreamRequest() {
        let endpoint = getMockEndpoint()
        var headers = Headers()
        headers.add(name: "header-item-name", value: "header-item-value")

        let httpBody = HttpBody.stream(ByteStream.from(data: expectedMockRequestData))
        mockHttpStreamRequest = SdkHttpRequest(method: .get, endpoint: endpoint, headers: headers, body: httpBody)
    }

    func getMockEndpoint() -> Endpoint {
        let path = "/path/to/endpoint"
        let host = "myapi.host.com"
        var queryItems: [URLQueryItem] = []
        let endpoint: Endpoint!

        queryItems.append(URLQueryItem(name: "qualifier", value: "qualifier-value"))
        endpoint = Endpoint(host: host, path: path, queryItems: queryItems)
        return endpoint
    }

    func testHttpStatusCodeDescriptionWorks() {
        let httpStatusCode = HttpStatusCode.ok
        let httpStatusCodeDescription = httpStatusCode.description

        XCTAssertNotNil(httpStatusCodeDescription)
    }
}
