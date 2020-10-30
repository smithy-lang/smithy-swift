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

import XCTest
@testable import ClientRuntime

class HttpRequestTests: NetworkingTestUtils {

    override func setUp() {
        super.setUp()
    }

    func testAsyncRequestToHttpRequest() {
        let httpRequest = mockHttpDataRequest.toHttpRequest()

        XCTAssertNotNil(httpRequest)
        for index in 0...(httpRequest.headerCount - 1) {
            let header1 = httpRequest.headers[index]
            let header2 = mockHttpDataRequest.headers.headers[index]
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
