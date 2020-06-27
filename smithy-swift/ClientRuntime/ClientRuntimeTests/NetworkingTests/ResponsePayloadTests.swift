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

class ResponsePayloadTests: XCTestCase {

    var responseAsJSONString: String!
    var responseAsXMLString: String!
    var decoder: ResponseDecoder!
    var expectedDecodedResponse: [String: String]!

    override func setUp() {
        responseAsJSONString = "{\"key\": \"value\"}"
        responseAsXMLString =
            """
            <root>
                <key>value</key>
            </root>
            """
        decoder = JSONDecoder()
        expectedDecodedResponse = ["key": "value"]
    }

    func testDecodingJSONResponsePayload() {
        let responsePayload = ResponsePayload(body: responseAsJSONString.data(using: .utf8)!, decoder: decoder)

        let result: Result<[String: String], SdkError<OperationError>> = responsePayload.decode()
            .mapError { failure in SdkError<OperationError>.client(failure) }

        let decodedResponse = try? result.get()

        XCTAssertNotNil(decodedResponse)
        XCTAssertEqual(decodedResponse, expectedDecodedResponse)
    }

    func testDecodingXMLResponsePayload() {
        decoder = XMLDecoder()
        let responsePayload = ResponsePayload(body: responseAsXMLString.data(using: .utf8)!, decoder: decoder)

        let result: Result<[String: String], SdkError<OperationError>> = responsePayload.decode()
            .mapError { failure in SdkError<OperationError>.client(failure) }

        let decodedResponse = try? result.get()

        XCTAssertNotNil(decodedResponse)
        XCTAssertEqual(decodedResponse, expectedDecodedResponse)
    }

    func testDecodingInvalidJSONResponsePayloadThrows() {
        let responsePayload = ResponsePayload(body: "{:}".data(using: .utf8)!, decoder: decoder)

        let result: Result<[String: String], SdkError<OperationError>> = responsePayload.decode()
            .mapError { failure in SdkError<OperationError>.client(failure) }
        switch result {
        case .failure(let clientError):
            XCTAssertNotNil(clientError)
        default:
            XCTFail("Decoding invalid payload is expected to fail")
        }
    }

    func testDecodingInvalidXMLResponsePayloadThrows() {
        decoder = XMLDecoder()
        let responsePayload = ResponsePayload(body: "{:}".data(using: .utf8)!, decoder: decoder)

        let result: Result<[String: String], SdkError<OperationError>> = responsePayload.decode()
            .mapError { failure in SdkError<OperationError>.client(failure) }
        switch result {
        case .failure(let clientError):
            XCTAssertNotNil(clientError)
        default:
            XCTFail("Decoding invalid payload is expected to fail")
        }
    }

    enum OperationError {
        case unknown(Error)
    }
}
