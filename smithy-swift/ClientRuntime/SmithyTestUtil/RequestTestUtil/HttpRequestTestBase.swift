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

/**
 Includes Utility functions for Http Protocol Serialization Tests
 */
open class HttpRequestTestBase: XCTestCase {
    /**
     Create `HttpRequest` from its components
     */
    public func buildExpectedHttpRequest(method: HttpMethodType,
                                         path: String,
                                         headers: [String: String],
                                         queryParams: [String],
                                         body: String?,
                                         host: String) -> HttpRequest {
        var queryItems = [URLQueryItem]()
        var httpHeaders = HttpHeaders()
        
        for queryParam in queryParams {
            let queryParamComponents = queryParam.components(separatedBy: "=")
            if queryParamComponents.count > 1 {
            queryItems.append(URLQueryItem(name: queryParamComponents[0], value: queryParamComponents[1].removingPercentEncoding))
            } else {
                queryItems.append(URLQueryItem(name: queryParamComponents[0], value: nil))
            }
        }
        
        for (headerName, headerValue) in headers {
            httpHeaders.add(name: headerName, value: headerValue)
        }
        
        let endPoint = Endpoint(host: host, path: path, queryItems: queryItems)
        
        guard let body = body else {
            return HttpRequest(method: method,
                               endpoint: endPoint,
                               headers: httpHeaders)
        }
        //handle empty string body cases that should still create a request
        //without the body
        if body == "" || body == "{}" {
            return HttpRequest(method: method,
                               endpoint: endPoint,
                               headers: httpHeaders)
        }
    
        let httpBody = HttpBody.data(body.data(using: .utf8))
        return HttpRequest(method: method,
                           endpoint: endPoint,
                           headers: httpHeaders,
                           body: httpBody)
        
    }
    
    /**
     Check if a Query Item with given name exists in array of `URLQueryItem`
     */
    public func queryItemExists(_ queryItemName: String, in queryItems: [URLQueryItem]?) -> Bool {
        guard let queryItems = queryItems else {
            return false
        }

        for queryItem in queryItems where queryItem.name == queryItemName {
            return true
        }
        return false
    }
    
    /**
    Check if a header with given name exists in array of `Header`
    */
    public func headerExists(_ headerName: String, in headers: [Header]) -> Bool {
        for header in headers where header.name == headerName {
            return true
        }
        return false
    }
    
    /**
     Asserts `HttpRequest` objects match
     /// - Parameter expected: Expected `HttpRequest`
     /// - Parameter actual: Actual `HttpRequest` to compare against
     /// - Parameter assertEqualHttpBody: Close to assert equality of `HttpBody` components
     */
    public func assertEqual(_ expected: HttpRequest, _ actual: HttpRequest, _ assertEqualHttpBody: (HttpBody?, HttpBody?) -> Void) {
        // assert headers match
        assertEqualHttpHeaders(expected.headers, actual.headers)
        
        // assert Endpoints match
        assertEqualEndpoint(expected.endpoint, actual.endpoint)
        
        // assert HttpMethod matches
        XCTAssertEqual(expected.method, actual.method)
        
        // assert the contents of HttpBody match
        assertEqualHttpBody(expected.body, actual.body)
    }
    
    /**
    Asserts `HttpBody` objects with Data objects match
    /// - Parameter expected: Expected `HttpBody`
    /// - Parameter actual: Actual `HttpBody` to compare against
    */
    public func assertEqualHttpBodyData(_ expected: HttpBody, _ actual: HttpBody) {
        if case .data(let actualData) = actual {
            if case .data(let expectedData) = expected {
                guard let expectedData  = expectedData else {
                    XCTAssertNil(actualData, "expected data in HttpBody is nil but actual is not")
                    return
                }
                
                guard let actualData = actualData else {
                    XCTFail("actual data in HttpBody is nil but expected is not")
                    return
                }
                XCTAssertEqual(expectedData, actualData, "The expected and Actual data inside the HttpBody do not match")
            } else {
                XCTFail("The expected HttpBody is not Data Type")
            }
        } else {
            XCTFail("The actual HttpBody is not Data Type")
        }
    }
    
    /**
    Asserts `HttpBody` objects with JSON Data match
    /// - Parameter expected: Expected `HttpBody`
    /// - Parameter actual: Actual `HttpBody` to compare against
    */
    public func assertEqualHttpBodyJSONData(_ expected: HttpBody, _ actual: HttpBody) {
        if case .data(let actualData) = actual {
            if case .data(let expectedData) = expected {
                guard let expectedData  = expectedData else {
                    XCTAssertNil(actualData, "expected data in HttpBody is nil but actual is not")
                    return
                }
                
                guard let actualData = actualData else {
                    XCTFail("actual data in HttpBody is nil but expected is not")
                    return
                }
                assertEqualJSON(expectedData, actualData)
            } else {
                XCTFail("The expected HttpBody is not Data Type")
            }
        } else {
            XCTFail("The actual HttpBody is not Data Type")
        }
    }
    
    /**
    Asserts JSON `Data` objects  match
    /// - Parameter expected: Expected JSON `Data`
    /// - Parameter actual: Actual JSON `Data` to compare against
    */
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
    
    /**
    Asserts `HttpHeaders` objects  match
    /// - Parameter expected: Expected `HttpHeaders`
    /// - Parameter actual: Actual `HttpHeaders` to compare against
    */
    public func assertEqualHttpHeaders(_ expected: HttpHeaders, _ actual: HttpHeaders) {
        for (expectedHeaderName, expectedHeaderValue) in expected.dictionary {
            guard let actualHeaderValue = actual.dictionary[expectedHeaderName] else {
                XCTFail("Expected Header \(expectedHeaderName) is not found in actual headers")
                return
            }
            XCTAssertEqual(expectedHeaderValue, actualHeaderValue,
                           "Expected Value of header \(expectedHeaderName) = \(expectedHeaderValue)]" +
                           " does not match actual header value \(actual.dictionary[expectedHeaderName])]")
        }
    }
    
    /**
    Asserts `Endpoint` objects  match
    /// - Parameter expected: Expected `Endpoint`
    /// - Parameter actual: Actual `Endpoint` to compare against
    */
    public func assertEqualEndpoint(_ expected: Endpoint, _ actual: Endpoint) {
        // match all the components of Endpoint
        XCTAssertEqual(expected.path, actual.path, "Expected Endpoint path: \(expected.path) does not match the actual Endpoint path: \(actual.path)")
        XCTAssertEqual(expected.protocolType, actual.protocolType,
                       "Expected Endpoint protocolType: \(expected.protocolType)" +
                       " does not match the actual Endpoint protocolType: \(actual.protocolType)")
        XCTAssertEqual(expected.host, actual.host, "Expected Endpoint host: \(expected.host) does not match the actual Endpoint host: \(actual.host)")
        XCTAssertEqual(expected.port, actual.port, "Expected Endpoint port: \(expected.port) does not match the actual Endpoint port: \(actual.port)")
        
        guard let expectedQueryItems = expected.queryItems else {
            XCTAssertNil(actual.queryItems, "expected query items in Endpoint is nil but actual are not")
            return
        }
        
        guard let actualQueryItems = actual.queryItems else {
            XCTFail("actual query items in Endpoint is nil but expected are not")
            return
        }
        assertEqualHttpQueryItems(expectedQueryItems, actualQueryItems)
        
    }
    
    /**
    Asserts that Http Query Items  match
    /// - Parameter expected: Expected array of Query Items
    /// - Parameter actual: Actual array of Query Items to compare against
    */
    public func assertEqualHttpQueryItems(_ expected: [URLQueryItem], _ actual: [URLQueryItem]) {
        for expectedQueryItem in expected {
            var queryItemFound = false
            
            // Compare the query item values
            for actualQueryItem in actual where expectedQueryItem.name == actualQueryItem.name {
                // considering case-sensitive query item names
                // query item found. compare values
                queryItemFound = true
                XCTAssertEqual(expectedQueryItem.value, actualQueryItem.value,
                               "Expected query item [\(expectedQueryItem.name)=\(expectedQueryItem.value)]" +
                               " does not match actual query item [\(actualQueryItem.name)=\(actualQueryItem.value)]")
                break
            }
            
            XCTAssertTrue(queryItemFound, "Expected query item \(expectedQueryItem.name) is not found in actual query items")
        }
    }
}
