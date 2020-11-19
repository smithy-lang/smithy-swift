//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

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

        let httpBody = HttpBody.stream(StreamSource(data: expectedMockRequestData))
        mockHttpStreamRequest = SdkHttpRequest(method: .get, endpoint: endpoint, headers: headers, body: httpBody)
    }

    func getMockEndpoint() -> Endpoint {
        let path = "/path/to/endpoint"
        let host = "myapi.host.com"
        var queryItems = [URLQueryItem]()
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
