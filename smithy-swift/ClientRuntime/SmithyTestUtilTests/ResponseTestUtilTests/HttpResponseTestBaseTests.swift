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

@testable import SmithyTestUtil
import ClientRuntime
import XCTest

class HttpResponseTestBaseTests: HttpResponseTestBase {
    let host = "myapi.host.com"
    
    func testBuildHttpResponse() {
        let statusCode = 200
        let headers = ["headerKey1": "headerValue1", "headerKey2": "headerValue2"]
        let bodyData = "{\"greeting\": \"Hello There\"}".data(using: .utf8)!
        let content = ResponseType.data(bodyData)
        
        guard let httpResponse = buildHttpResponse(code: statusCode, headers: headers, content: content, host: host) else {
            XCTFail("Failed to build Http Response")
            return
        }
        
        XCTAssertEqual(headers, httpResponse.headers.dictionary.mapValues({ (values) -> String in
            values.joined(separator: ", ")
        }))
        
        XCTAssertEqual(HttpStatusCode(rawValue: statusCode), httpResponse.statusCode)
        
        if case .data(let actualData) = httpResponse.content {
            XCTAssertEqual(bodyData, actualData)
        } else {
            XCTFail("HttpResponse Content unexpectedly found to be nil")
        }
    }
}
