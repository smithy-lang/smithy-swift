/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

@testable import SmithyTestUtil
import ClientRuntime
import XCTest

class HttpRequestTestBaseTests: HttpRequestTestBase {
    static let host = "myapi.host.com"
    
    struct SayHelloInput: Encodable, HttpRequestBinding {
        func buildHttpRequest(encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {

            var queryItems: [URLQueryItem] = [URLQueryItem]()
            var queryItem: URLQueryItem
            if let requiredQuery = requiredQuery {
                queryItem = URLQueryItem(name: "RequiredQuery", value: String(requiredQuery))
                queryItems.append(queryItem)
            }
            
            var headers = Headers()
            headers.add(name: "Content-Type", value: "application/json")
            if let requiredHeader = requiredHeader {
                headers.add(name: "RequiredHeader", value: requiredHeader)
            }
            let body = HttpBody.data(try? encoder.encode(self))
            let builder = SdkHttpRequestBuilder()
                .withBody(body)
                .withHeaders(headers)
                .withQueryItems(queryItems)
            return builder
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

    struct SayHelloInputBody: Decodable, Equatable {
        public let greeting: String?

        private enum CodingKeys: String, CodingKey {
            case greeting
        }
        public init (from decoder: Decoder) throws {
            let containerValues = try decoder.container(keyedBy: CodingKeys.self)
            let greetingDecoded = try containerValues.decodeIfPresent(String.self, forKey: .greeting)
            greeting = greetingDecoded
        }
    }

    // Mocks the code-generated unit test which includes testing for forbidden/required headers/queries
    func testSayHello() {
        let expected = buildExpectedHttpRequest(method: .post,
                                                path: "/",
                                                headers: ["Content-Type": "application/json",
                                                          "RequiredHeader": "required header"],
                                                queryParams: ["RequiredQuery=required%20query"],
                                                body: "{\"greeting\": \"Hello There\"}",
                                                host: HttpRequestTestBaseTests.host)
        
        let input = SayHelloInput(greeting: "Hello There",
                                  forbiddenQuery: "forbidden query",
                                  requiredQuery: "required query",
                                  forbiddenHeader: "forbidden header",
                                  requiredHeader: "required header")
        do {
        let actualBuilder = try input.buildHttpRequest(encoder: JSONEncoder())
        let actual = actualBuilder.build()
        let forbiddenQueryParams = ["ForbiddenQuery"]
        // assert forbidden query params do not exist
        for forbiddenQueryParam in forbiddenQueryParams {
            XCTAssertFalse(
                queryItemExists(forbiddenQueryParam, in: actual.endpoint.queryItems),
                "Forbidden Query:\(forbiddenQueryParam) exists in query items"
            )
        }
        
        let forbiddenHeaders = ["ForbiddenHeader"]
        // assert forbidden headers do not exist
        for forbiddenHeader in forbiddenHeaders {
            XCTAssertFalse(headerExists(forbiddenHeader, in: actual.headers.headers),
                           "Forbidden Header:\(forbiddenHeader) exists in headers")
        }
        
        let requiredQueryParams = ["RequiredQuery"]
        // assert forbidden query params do not exist
        for requiredQueryParam in requiredQueryParams {
            XCTAssertTrue(queryItemExists(requiredQueryParam, in: actual.endpoint.queryItems),
                           "Required Query:\(requiredQueryParam) does not exist in query items")
        }
        
        let requiredHeaders = ["RequiredHeader"]
        // assert forbidden headers do not exist
        for requiredHeader in requiredHeaders {
            XCTAssertTrue(headerExists(requiredHeader, in: actual.headers.headers),
                           "Required Header:\(requiredHeader) does not exist in headers")
        }
        
        assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
            XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
            XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
            extractHttpBodyJSONData(expectedHttpBody!, actualHttpBody!) { (expectedData, actualData) in
                do {
                     let decoder = JSONDecoder()
                     let expectedObj = try decoder.decode(SayHelloInputBody.self, from: expectedData)
                     let actualObj = try decoder.decode(SayHelloInputBody.self, from: actualData)
                     XCTAssertEqual(expectedObj, actualObj)
                 } catch let err {
                     XCTFail("Failed to verify body \(err)")
                 }
            }
        })
        } catch {
            XCTFail("Encoding of request failed")
        }
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
