/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
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
    
    func testConversionToUrlRequestFailsWithInvalidEndpoint() {
        // TODO:: When is the endpoint invalid or endpoint.url nil?
        _ = Endpoint(host: "", path: "", protocolType: nil)
    }
}
