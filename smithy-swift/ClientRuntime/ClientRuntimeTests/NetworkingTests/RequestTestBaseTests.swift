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

import ClientRuntime
import XCTest

class RequestTestBaseTests: RequestTestBase {
    static let host = "myapi.host.com"
    
    struct SayHelloInput: Encodable, HttpRequestBinding {
        func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
            var queryItems: [URLQueryItem] = [URLQueryItem]()
            var queryItem: URLQueryItem
            if let requiredQuery = requiredQuery {
                queryItem = URLQueryItem(name: "RequiredQuery", value: String(requiredQuery))
                queryItems.append(queryItem)
            }
            let endpoint = Endpoint(host: host , path: path, queryItems: queryItems)
            var headers = HttpHeaders()
            headers.add(name: "Content-Type", value: "application/json")
            if let requiredHeader = requiredHeader {
                headers.add(name: "RequiredHeader", value: requiredHeader)
            }
            return HttpRequest(method: method, endpoint: endpoint, headers: headers)
        }
        
        let greeting: String?
        let forbiddenQuery: String?
        let requiredQuery: String?
        let forbiddenHeader: String?
        let requiredHeader: String?
        
        init(greeting: String?,
             forbiddenQuery: String?,
             requiredQuery: String?,
             forbiddenHeader: String?,
             requiredHeader: String?) {
            self.greeting = greeting
            self.forbiddenQuery = forbiddenQuery
            self.requiredQuery = requiredQuery
            self.forbiddenHeader = forbiddenHeader
            self.requiredHeader = requiredHeader
        }
        
        private enum CodingKeys: String, CodingKey {
            case greeting
        }
    }

    
    override func setUp() {
        super.setUp()
    }
    
    // Mocks the code-generated unit test which includes testing for forbidden/required headers/queries
    func testSayHello() {
        let expected = buildExpectedHttpRequest(method: .post,
                                                path: "/",
                                                headers: ["Content-Type": "application/json",
                                                          "RequiredHeader": "required header"],
                                                queryParams:["RequiredQuery=required%20query"],
                                                body: "{\"greeting\": \"Hello There\"}",
                                                host: RequestTestBaseTests.host)
        
        let forbiddenQueryParams = ["ForbiddenQuery"]
        let requiredQueryParams = ["RequiredQuery"]
        let forbiddenHeaders = ["ForbiddenHeader"]
        let requiredHeaders = ["RequiredHeader"]
        
        let input = SayHelloInput(greeting: "Hello There",
                                  forbiddenQuery: "forbidden query",
                                  requiredQuery: "required query",
                                  forbiddenHeader: "forbidden header",
                                  requiredHeader: "required header")
        var actual = input.buildHttpRequest(method: .post, path: "/")
        
        do {
            _ = try JSONEncoder().encodeHttpRequest(input, currentHttpRequest: &actual)
        }  catch let err {
            XCTFail("Failed to encode the input. Error description: \(err)")
        }
        
        // assert forbidden query params do not exist
        for forbiddenQueryParam in forbiddenQueryParams {
            XCTAssertFalse(queryItemExists(forbiddenQueryParam, in: actual.endpoint.queryItems),
                           "Forbidden Query:\(forbiddenQueryParam) exists in query items")
        }
        
        // assert forbidden headers do not exist
        for forbiddenHeader in forbiddenHeaders {
            XCTAssertFalse(headerExists(forbiddenHeader, in: actual.headers.headers),
                           "Forbidden Header:\(forbiddenHeader) exists in headers")
        }
        
        // assert forbidden query params do not exist
        for requiredQueryParam in requiredQueryParams {
            XCTAssertTrue(queryItemExists(requiredQueryParam, in: actual.endpoint.queryItems),
                           "Required Query:\(requiredQueryParam) does not exist in query items")
        }
        
        // assert forbidden headers do not exist
        for requiredHeader in requiredHeaders {
            XCTAssertTrue(headerExists(requiredHeader, in: actual.headers.headers),
                           "Required Header:\(requiredHeader) does not exist in headers")
        }
        
        assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
            XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
            XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
            assertEqualHttpBodyJSONData(expectedHttpBody!, actualHttpBody!)
        })
        
        //use mock engine to fake request and then assert correct url is used
        _ = httpClient.execute(request: actual) { _ in }

        XCTAssert(mockSession.lastURL == expected.endpoint.url)
    }
    
    func testJSONEqual () throws {
        let jsonString =
        """
        {
          "Actors": [
            {
              "name": "Tom Cruise",
              "age": 56,
              "Born At": "Syracuse, NY",
              "Birthdate": "July 3, 1962",
              "wife": null,
              "weight": 67.5,
              "hasChildren": true,
              "hasGreyHair": false,
              "children": [
                "Suri",
                "Isabella Jane",
                "Connor"
              ]
            },
            {
              "name": "Robert Downey Jr.",
              "age": 53,
              "Born At": "New York City, NY",
              "Birthdate": "April 4, 1965",
              "wife": "Susan Downey",
              "weight": 77.1,
              "hasChildren": true,
              "hasGreyHair": false,
              "children": [
                "Indio Falconer",
                "Avri Roel",
                "Exton Elias"
              ]
            }
          ]
        }
        """
        
        let jsonStringWithDifferentOrder =
        """
        {
          "Actors": [
            {
              "name": "Tom Cruise",
              "age": 56,
              "Birthdate": "July 3, 1962",
              "Born At": "Syracuse, NY",
              "wife": null,
              "weight": 67.5,
              "hasGreyHair": false,
              "hasChildren": true,
              "children": [
                "Suri",
                "Isabella Jane",
                "Connor"
              ]
            },
            {
              "children": [
                "Indio Falconer",
                "Avri Roel",
                "Exton Elias"
              ],
                  "name": "Robert Downey Jr.",
                "age": 53,
               "Born At": "New York City, NY",
              "Birthdate": "April 4, 1965",
              "wife": "Susan Downey",
              "weight": 77.1,
              "hasChildren": true,
              "hasGreyHair": false
            }
          ]
        }
        """
        assertEqualJSON(jsonString.data(using: .utf8)!, jsonStringWithDifferentOrder.data(using: .utf8)!)
    }

}
