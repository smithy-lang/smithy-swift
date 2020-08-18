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

class RequestTestBase: NetworkingTestUtils {
    var httpClient: HttpClient!
    let mockSession = MockURLSession()
    
    override func setUp() {
        super.setUp()
        let httpClientConfiguration = HttpClientConfiguration(operationQueue: mockOperationQueue)
        httpClient = HttpClient(session: mockSession, config: httpClientConfiguration)
    }
    
    public func buildExpectedHttpRequest(method: HttpMethodType,
                                         path: String,
                                         headers: [String: String],
                                         queryParams: [String],
                                         body: String,
                                         host: String) -> HttpRequest {
        var queryItems = [URLQueryItem]()
        var httpHeaders = HttpHeaders()
        
        for queryParam in queryParams {
            let queryParamComponents = queryParam.components(separatedBy: "=")
            queryItems.append(URLQueryItem(name: queryParamComponents[0], value: queryParamComponents[1].removingPercentEncoding))
        }
        
        for (headerName, headerValue) in headers {
            httpHeaders.add(name: headerName, value: headerValue)
        }
        
        let endPoint = Endpoint(host: host, path: path, queryItems: queryItems)
        let httpBody = HttpBody.data(body.data(using: .utf8))
        return HttpRequest(method: method,
                           endpoint: endPoint,
                           headers: httpHeaders,
                           body: httpBody)
    }
    
    public func assertEqual(_ expected: HttpRequest, _ actual: HttpRequest, _ assertEqualHttpBody: (HttpBody?, HttpBody?) -> Void) {
        // assert headers match
        XCTAssertEqual(expected.headers, actual.headers)
        
        // assert Endpoints match
        XCTAssertEqual(expected.endpoint, actual.endpoint)
        
        // assert HttpMethod matches
        XCTAssertEqual(expected.method, actual.method)
        
        // assert the contents of HttpBody match
        assertEqualHttpBody(expected.body, actual.body)
    }
    
    public func assertEqualHttpBodyJSONData(_ expected: HttpBody, _ actual: HttpBody) {
        switch actual {
        case let .data(actualData):
            switch expected {
            case let .data(expectedData):
                // convert data back to string with utf8 encoding and compare based on the media type
                guard let expectedData = expectedData else {
                    XCTAssertNil(actualData, "expected data in HttpBody is nil but actual is not")
                    return
                }
                
                guard let actualData = actualData else {
                    XCTFail("actual data in HttpBody is nil but expected is not")
                    return
                }
                assertEqualJSON(expectedData, actualData)
            default: XCTFail("The expected HttpBody is not Data Type")
            }
        default: XCTFail("The actual HttpBody is not Data Type")
        }
    }
    
    public func assertEqualJSON(_ expected: Data, _ actual: Data) {
        guard let expectedJSON = try? JSONSerialization.jsonObject(with: expected) as? [String: Any] else {
            XCTFail("The expected JSON Data is not Valid")
            return
        }
        
        guard let actualJSON = try? JSONSerialization.jsonObject(with: actual) as? [String: Any] else {
            XCTFail("The actual JSON Data is not Valid")
            return
        }
        
        XCTAssertTrue((expectedJSON as NSDictionary).isEqual(to: actualJSON))
    }
    
    public func queryItemExists(_ queryItemName: String, in queryItems: [URLQueryItem]?) -> Bool {
        guard let queryItems = queryItems else {
            return false
        }
        
        for queryItem in queryItems {
            if (queryItem.name == queryItemName){
                return true
            }
        }
        return false
    }
    
    public func headerExists(_ headerName: String, in headers: [Header]) -> Bool {
        for header in headers {
            if (header.name == headerName){
                return true
            }
        }
        return false
    }
}
