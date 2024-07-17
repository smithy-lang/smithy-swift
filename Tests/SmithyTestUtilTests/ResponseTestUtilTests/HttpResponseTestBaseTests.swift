/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Smithy
import SmithyHTTPAPI
@testable import SmithyTestUtil
import ClientRuntime
import XCTest
import AwsCommonRuntimeKit

class HttpResponseTestBaseTests: HttpResponseTestBase {

    func testBuildHttpResponse() {
        let statusCode = 200
        let headers = ["headerKey1": "headerValue1", "headerKey2": "headerValue2"]
        let bodyData = "{\"greeting\": \"Hello There\"}".data(using: .utf8)!
        let content = ByteStream.data(bodyData)

        guard let httpResponse = buildHttpResponse(code: statusCode, headers: headers, content: content) else {
            XCTFail("Failed to build Http Response")
            return
        }

        XCTAssertEqual(headers, httpResponse.headers.dictionary.mapValues({ (values) -> String in
            values.joined(separator: ", ")
        }))

        XCTAssertEqual(HTTPStatusCode(rawValue: statusCode), httpResponse.statusCode)

        if case .data(let actualData) = httpResponse.body {
            XCTAssertEqual(bodyData, actualData)
        } else {
            XCTFail("HttpResponse Content unexpectedly found to be nil")
        }
    }
}
