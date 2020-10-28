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

    func testHttpDataRequestToUrlRequest() {
        let urlRequest = try? mockHttpDataRequest.toUrlRequest()

        XCTAssertNotNil(urlRequest)

        XCTAssertEqual(urlRequest!.headers.dictionary, mockHttpDataRequest.headers.dictionary)
        XCTAssertEqual(urlRequest!.httpMethod, "GET")
        XCTAssertEqual(urlRequest?.httpBody, expectedMockRequestData)
        XCTAssertEqual(urlRequest!.url, expectedMockRequestURL)
    }

    func testHttpStreamRequestToUrlRequest() {
        let urlRequest = try? mockHttpStreamRequest.toUrlRequest()

        XCTAssertNotNil(urlRequest)

        XCTAssertEqual(urlRequest!.headers.dictionary, mockHttpStreamRequest.headers.dictionary)
        XCTAssertEqual(urlRequest!.httpMethod, "GET")

        let dataFromStream = try? Data(reading: urlRequest!.httpBodyStream!)
        XCTAssertNotNil(dataFromStream)

        XCTAssertEqual(dataFromStream, expectedMockRequestData)
        XCTAssertEqual(urlRequest!.url, expectedMockRequestURL)
    }

    func testConversionToUrlRequestFailsWithInvalidEndpoint() {
        // TODO:: When is the endpoint invalid or endpoint.url nil?
        _ = Endpoint(host: "", path: "", protocolType: nil)
    }
}
