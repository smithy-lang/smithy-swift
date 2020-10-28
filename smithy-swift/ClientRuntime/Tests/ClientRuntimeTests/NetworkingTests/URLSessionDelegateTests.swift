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

class URLSessionDelegateTests: NetworkingTestUtils {

    var httpClient: HttpClient!
    var expectedResponsePayload: Data!

    override func setUp() {
        super.setUp()
        let httpClientConfiguration = HttpClientConfiguration(operationQueue: mockOperationQueue, protocolClasses: [MockURLProtocol.self])
        httpClient = HttpClient(config: httpClientConfiguration)
        expectedResponsePayload = "{resultKey: resultValue}".data(using: .utf8)!
    }

    override func tearDown() {
        super.tearDown()
    }

    func testValidResponseDataIsReturned() {
        let validResponseDataExpectation: XCTestExpectation = expectation(description: "Mock Request returns valid response data payload")
        setMockProtocolResponse(responsePayload: expectedResponsePayload, statusCode: 200)

        _ = httpClient.execute(request: mockHttpDataRequest) { (httpResult) in
            guard let httpResp = try? httpResult.get() else {
                XCTFail("Http Response found to be nil")
                validResponseDataExpectation.fulfill()
                return
            }

            if httpResp.statusCode == HttpStatusCode.ok {
                if case .data(let data) = httpResp.content {
                    XCTAssertEqual(data, self.expectedResponsePayload)
                } else {
                    XCTFail("Http Response content has no valid data")
                    validResponseDataExpectation.fulfill()
                    return
                }
            } else {
                XCTFail("Mock Http Request failed")
                validResponseDataExpectation.fulfill()
                return
            }
            validResponseDataExpectation.fulfill()
        }

        wait(for: [validResponseDataExpectation], timeout: 20)
    }

    func testResponseWithEmptyPayloadIsHandled() {
        let emptyResponseExpectation: XCTestExpectation = expectation(description: "Mock invalid Request returns Error")
        setMockProtocolResponse(responsePayload: Data(), statusCode: 200)

        _ = httpClient.execute(request: mockHttpDataRequest) { (httpResult) in
            guard let httpResp = try? httpResult.get() else {
                XCTFail("Http Response found to be nil")
                emptyResponseExpectation.fulfill()
                return
            }

            if httpResp.statusCode == HttpStatusCode.ok {
                if case .data( _) = httpResp.content {
                    XCTFail("Empty response payload is expected")
                    emptyResponseExpectation.fulfill()
                    return
                }
            } else {
                XCTFail("Mock Http Request failed")
                emptyResponseExpectation.fulfill()
                return
            }
            emptyResponseExpectation.fulfill()
        }

        wait(for: [emptyResponseExpectation], timeout: 20)
    }

    func testFailureHttpStatusCodeIsCaptured() {
        let failedResponseExpectation: XCTestExpectation = expectation(description: "Mock invalid Request returns Error")
        setMockProtocolResponse(responsePayload: Data(), statusCode: 404)

        _ = httpClient.execute(request: mockHttpDataRequest) { (httpResult) in
            guard let httpResp = try? httpResult.get() else {
                XCTFail("Http Response found to be nil")
                failedResponseExpectation.fulfill()
                return
            }

            if httpResp.statusCode == HttpStatusCode.ok {
                XCTFail("Client returns OK status for failed response")
                failedResponseExpectation.fulfill()
                return
            } else {
                XCTAssertEqual(httpResp.statusCode.rawValue, 404)
            }
            failedResponseExpectation.fulfill()
        }

        wait(for: [failedResponseExpectation], timeout: 20)
    }

    func setMockProtocolResponse(responsePayload: Data, statusCode: Int) {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: self.expectedMockRequestURL, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            return (response, responsePayload)
        }
    }

}
