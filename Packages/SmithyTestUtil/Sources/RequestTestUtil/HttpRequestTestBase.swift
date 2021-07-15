//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import XCTest

/**
 Includes Utility functions for Http Protocol Request Serialization Tests
 */
public typealias ValidateCallback = (Data, Data) -> Void

open class HttpRequestTestBase: XCTestCase {
    /**
     Create `HttpRequest` from its components
     */
    public func buildExpectedHttpRequest(method: HttpMethodType,
                                         path: String,
                                         headers: [String: String],
                                         queryParams: [String],
                                         body: String?,
                                         host: String) -> SdkHttpRequest {
        let builder = SdkHttpRequestBuilder()
        
        for queryParam in queryParams {
            let queryParamComponents = queryParam.components(separatedBy: "=")
            if queryParamComponents.count > 1 {
                let value = sanitizeStringForNonConformingValues(queryParamComponents[1])

                builder.withQueryItem(URLQueryItem(name: queryParamComponents[0],
                                                   value: value))
            } else {
                builder.withQueryItem(URLQueryItem(name: queryParamComponents[0], value: nil))
            }
        }
        
        for (headerName, headerValue) in headers {
            let value = sanitizeStringForNonConformingValues(headerValue)
            builder.withHeader(name: headerName, value: value)
        }
        
        guard let body = body else {
            return builder.build()
        }
        // handle empty string body cases that should still create a request
        // without the body
        if body != "" && body != "{}" {
            let httpBody = HttpBody.data(body.data(using: .utf8))
            builder.withBody(httpBody)
        }
    
        return builder.build()
        
    }
    
    func sanitizeStringForNonConformingValues(_ input: String) -> String {
        switch input {
        case "Infinity": return "inf"
        case "-Infinity": return "-inf"
        case "NaN": return "nan"
        default:
            return input
        }
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
    public func assertEqual(_ expected: SdkHttpRequest,
                            _ actual: SdkHttpRequest,
                            _ assertEqualHttpBody: (HttpBody?, HttpBody?) -> Void) {
        // assert headers match
        assertEqualHttpHeaders(expected.headers, actual.headers)
        
        // assert Endpoints match
        assertEqualQueryItems(expected.queryItems, actual.queryItems)
        
        // assert the contents of HttpBody match
        assertEqualHttpBody(expected.body, actual.body)
    }
    
    public func genericAssertEqualHttpBodyData(_ expected: HttpBody, _ actual: HttpBody, _ callback: (Data, Data) -> Void) {
        guard case .success(let expectedData) = extractData(expected) else {
            XCTFail("Failed to extract data from httpbody for expected")
            return
        }
        guard case .success(let actualData) = extractData(actual) else {
            XCTFail("Failed to extract data from httpbody for actual")
            return
        }
        if shouldCompareData(expectedData, actualData) {
            callback(expectedData!, actualData!)
        }
    }

    private func extractData(_ httpBody: HttpBody) -> Result<Data?, Error> {
        switch httpBody {
        case .data(let actualData):
            return .success(actualData)
        case .stream(let byteStream):
            return .success(byteStream.readFrom().byteBuffer.toData())
        case .none:
            return .failure(InternalHttpRequestTestBaseError("HttpBody is not Data Type"))
        }
    }

    private func shouldCompareData(_ expected: Data?, _ actual: Data?) -> Bool {
        if expected == nil && actual == nil {
            return false
        } else if expected != nil && actual == nil {
            XCTFail("actual data in HttpBody is nil but expected is not")
            return false
        } else if expected == nil && actual != nil {
            XCTFail("expected data in HttpBody is nil but actual is not")
            return false
        }
        return true
    }

    /**
    Asserts `HttpHeaders` objects  match
    /// - Parameter expected: Expected `HttpHeaders`
    /// - Parameter actual: Actual `HttpHeaders` to compare against
    */
    public func assertEqualHttpHeaders(_ expected: Headers, _ actual: Headers) {
        // in order to properly compare header values where actual is an array and expected comes in
        // as a comma separated string take actual and join them with a comma and then separate them
        // by comma (to in effect get the same separated list as expected) take expected and separate them
        // by comma then throw both actual and expected comma separated arrays in a set and compare sets
        let sortedActualHeaders = actual.dictionary.mapValues({ (values) -> Set<String> in
            let joinedValues = values.joined(separator: ", ")
            let splitValues = joinedValues.components(separatedBy: ", ")
            var set = Set<String>()
            splitValues.forEach { (value) in
                set.insert(value)
            }
            return set
        })
        let sortedExpectedHeaders = expected.dictionary.mapValues { (values) -> Set<String> in
            var set = Set<String>()
            values.forEach { (value) in
                let components = value.components(separatedBy: ", ")
                components.forEach { (arrayValue) in
                    set.insert(arrayValue)
                }
            }
            return set
        }
        for (expectedHeaderName, expectedHeaderValue) in sortedExpectedHeaders {
            guard let actualHeaderValue = sortedActualHeaders[expectedHeaderName] else {
                XCTFail("Expected Header \(expectedHeaderName) is not found in actual headers")
                return
            }
            
            XCTAssertEqual(expectedHeaderValue, actualHeaderValue,
                           "Expected Value of header \(expectedHeaderName) = \(expectedHeaderValue)]" +
                            " does not match actual header value" +
                            "\(String(describing: actual.dictionary[expectedHeaderName]))]")
        }
    }
    
    public func assertEqualQueryItems(_ expected: [URLQueryItem]?, _ actual: [URLQueryItem]?) {
        guard let expectedQueryItems = expected else {
            XCTAssertNil(actual, "expected query items is nil but actual are not")
            return
        }
        guard let actualQueryItems = actual else {
            XCTFail("actual query items in Endpoint is nil but expected are not")
            return
        }

        let expectedKVCount = generateKeyValueDictionaryCount(expectedQueryItems)
        let actualKVCount = generateKeyValueDictionaryCount(actualQueryItems)

        XCTAssert(expectedQueryItems.count == actualQueryItems.count, "Number of query params does not match")
        for (keyValue, expectedCount) in expectedKVCount {
            XCTAssert(actualKVCount[keyValue] == expectedCount, "Expected \(keyValue) to appear \(expectedCount) times.  Actual: \(actualKVCount[keyValue] ?? 0)")
        }
    }

    private func generateKeyValueDictionaryCount(_ urlQueryItems: [URLQueryItem]) -> [String: Int] {
        var dict: [String: Int] = [:]
        for urlQueryItem in urlQueryItems {
            let name = urlQueryItem.name
            let value = urlQueryItem.value ?? "nil"
            let key = "\(name)=\(value)"
            if let value = dict[key] {
                dict[key] = value + 1
            } else {
                dict[key] = 1
            }
        }
        return dict
    }
    
    struct InternalHttpRequestTestBaseError: Error {
        let localizedDescription: String
        public init(_ description: String) {
            self.localizedDescription = description
        }
    }
}
