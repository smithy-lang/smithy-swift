//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import SmithyHTTPAPI
import XCTest

final class HTTPResponseRequestIDTests: XCTestCase {

    func test_requestID_itReadsTheAmzRequestIDHeader() {
        XCTAssertEqual(response(["x-amz-request-id": "abc"]).requestID, "abc")
    }

    func test_requestID_itFallsBackToTheAmznRequestIdHeader() {
        XCTAssertEqual(response(["x-amzn-RequestId": "def"]).requestID, "def")
        XCTAssertEqual(response(["X-Amzn-Requestid": "ghi"]).requestID, "ghi")
    }

    func test_requestID_itPrefersTheAmzRequestIDHeader() {
        XCTAssertEqual(response(["x-amzn-RequestId": "def", "x-amz-request-id": "abc"]).requestID, "abc")
    }

    func test_requestID_itIsNilWithoutARequestIDHeader() {
        XCTAssertNil(response(["x-other": "x"]).requestID)
    }

    func test_httpError_itProvidesTheRequestIDsFromItsHTTPResponse() {
        let error = UnknownHTTPServiceError(httpResponse: response(["x-amzn-RequestId": "abc", "x-amz-id-2": "def"]))

        XCTAssertEqual(error.requestID, "abc")
        XCTAssertEqual(error.requestID2, "def")
    }

    func test_httpError_itProvidesTheRequestIDsOfAModeledError() {
        var error = TestModeledError()
        XCTAssertNil(error.requestID)

        error.httpResponse = response(["x-amz-request-id": "abc", "x-amz-id-2": "def"])

        XCTAssertEqual(error.requestID, "abc")
        XCTAssertEqual(error.requestID2, "def")
    }

    private func response(_ headers: [String: String]) -> HTTPResponse {
        var allHeaders = Headers()
        for (name, value) in headers { allHeaders.add(name: name, value: value) }
        return HTTPResponse(headers: allHeaders, body: .noStream, statusCode: .badRequest)
    }
}

/// An error declared the way codegen declares a modeled error, with no stored request IDs.
private struct TestModeledError: ServiceError, HTTPError, Error {
    var typeName: String? { "TestModeledError" }
    var message: String?
    var httpResponse = HTTPResponse(body: .noStream, statusCode: .badRequest)
}
