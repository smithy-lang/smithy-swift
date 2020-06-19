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
    
    var mockHttpDataRequest: HttpRequest!
    var expectedMockRequestURL: URL!
    var expectedMockRequestData: Data!
    var mockOperationQueue: OperationQueue!
    
    override func setUp() {
        super.setUp()
        expectedMockRequestURL = URL(string: "https://myapi.host.com/path/to/endpoint?qualifier=qualifier-value")!
        let mockRequestBody = "{parameter:value}"
        expectedMockRequestData = mockRequestBody.data(using: .utf8)
        mockOperationQueue = OperationQueue()
        mockOperationQueue.name = "mock-operation-queue"
        setMockHttpDataRequest()
    }
    
    /*
     Create a mock HttpRequest with valid data payload
     */
    func setMockHttpDataRequest() {
        let path = "/path/to/endpoint"
        let host = "myapi.host.com"
        var queryItems = [URLQueryItem]()
        var endpoint: Endpoint!
        var headers = HttpHeaders()
        
        queryItems.append(URLQueryItem(name: "qualifier", value: "qualifier-value"))
        endpoint = Endpoint(host: host, path: path, queryItems: queryItems)
        headers.add(name: "header-item-name", value: "header-item-value")
        
        let httpBody = HttpBody.data(expectedMockRequestData)
        mockHttpDataRequest = HttpRequest(method: .get, endpoint: endpoint, headers: headers, body: httpBody)
    }
    
    func testHttpStatusCodeDescriptionWorks() {
        let httpStatusCode = HttpStatusCode.ok
        let httpStatusCodeDescription = httpStatusCode.description
        
        XCTAssertNotNil(httpStatusCodeDescription)
    }
}
