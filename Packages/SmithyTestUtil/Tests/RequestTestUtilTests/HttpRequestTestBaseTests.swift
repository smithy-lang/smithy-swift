/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import SmithyTestUtil
import ClientRuntime
import XCTest

class HttpRequestTestBaseTests: HttpRequestTestBase {
    static let host = "myapi.host.com"
    
    struct SayHelloInputQueryItemMiddleware<StackOutput: HttpResponseBinding,
                                            StackError: HttpResponseBinding>: Middleware {

        var id: String = "SayHelloInputQueryItemMiddleware"
        
        func handle<H>(context: HttpContext,
                       input: SerializeStepInput<SayHelloInput>,
                       next: H) -> Result<OperationOutput<StackOutput, StackError>, Error> where H: Handler,
                                                                Self.Context == H.Context,
                                                                Self.MInput == H.Input,
                                                                Self.MOutput == H.Output {
            var queryItems: [URLQueryItem] = [URLQueryItem]()
            var queryItem: URLQueryItem
            if let requiredQuery = input.operationInput.requiredQuery {
                queryItem = URLQueryItem(name: "RequiredQuery", value: String(requiredQuery))
                queryItems.append(queryItem)
            }
            
            input.builder.withQueryItems(queryItems)
            return next.handle(context: context, input: input)
        }
        
        typealias MInput = SerializeStepInput<SayHelloInput>
        
        typealias MOutput = OperationOutput<StackOutput, StackError>
        
        typealias Context = HttpContext
    }
    
    struct SayHelloInputHeaderMiddleware<StackOutput: HttpResponseBinding,
                                         StackError: HttpResponseBinding>: Middleware {
        var id: String = "SayHelloInputHeaderMiddleware"
        
        func handle<H>(context: HttpContext,
                       input: MInput,
                       next: H) -> Result<MOutput, Error> where H: Handler,
                                                                Self.Context == H.Context,
                                                                Self.MInput == H.Input,
                                                                Self.MOutput == H.Output {
            var headers = Headers()
            headers.add(name: "Content-Type", value: "application/json")
            if let requiredHeader = input.operationInput.requiredHeader {
                headers.add(name: "RequiredHeader", value: requiredHeader)
            }
            input.builder.withHeaders(headers)
            return next.handle(context: context, input: input)
        }
        
        typealias MInput = SerializeStepInput<SayHelloInput>
        
        typealias MOutput = OperationOutput<StackOutput, StackError>
        
        typealias Context = HttpContext
    }
    
    struct SayHelloInputBodyMiddleware<StackOutput: HttpResponseBinding,
                                       StackError: HttpResponseBinding>: Middleware {
        var id: String = "SayHelloInputBodyMiddleware"
        
        func handle<H>(context: HttpContext,
                       input: MInput,
                       next: H) -> Result<MOutput, Error> where H: Handler,
                                                                Self.Context == H.Context,
                                                                Self.MInput == H.Input,
                                                                Self.MOutput == H.Output {
            do {
                let encoder = context.getEncoder()
                let body = HttpBody.data(try encoder.encode(input.operationInput))
                input.builder.withBody(body)
                return next.handle(context: context, input: input)
            } catch let err {
                return .failure(err)
            }
        }
        
        typealias MInput = SerializeStepInput<SayHelloInput>
        
        typealias MOutput = OperationOutput<StackOutput, StackError>
        
        typealias Context = HttpContext
    }
    
    struct SayHelloInput: Encodable, Reflection {
        
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
        let deserializeMiddleware = expectation(description: "deserializeMiddleware")
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

        var operationStack = OperationStack<SayHelloInput, MockOutput, MockMiddlewareError>(id: "SayHelloInputRequest")
        operationStack.serializeStep.intercept(position: .before, middleware: SayHelloInputQueryItemMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: SayHelloInputHeaderMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: SayHelloInputBodyMiddleware())
        operationStack.deserializeStep.intercept(position: .after, middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(
            id: "TestDeserializeMiddleware") { _, actual in
            
            let forbiddenQueryParams = ["ForbiddenQuery"]
            for forbiddenQueryParam in forbiddenQueryParams {
                XCTAssertFalse(
                    self.queryItemExists(forbiddenQueryParam, in: actual.endpoint.queryItems),
                    "Forbidden Query:\(forbiddenQueryParam) exists in query items"
                )
            }
            let forbiddenHeaders = ["ForbiddenHeader"]
            for forbiddenHeader in forbiddenHeaders {
                XCTAssertFalse(self.headerExists(forbiddenHeader, in: actual.headers.headers),
                               "Forbidden Header:\(forbiddenHeader) exists in headers")
            }
            
            let requiredQueryParams = ["RequiredQuery"]
            for requiredQueryParam in requiredQueryParams {
                XCTAssertTrue(self.queryItemExists(requiredQueryParam, in: actual.endpoint.queryItems),
                              "Required Query:\(requiredQueryParam) does not exist in query items")
            }
            
            let requiredHeaders = ["RequiredHeader"]
            for requiredHeader in requiredHeaders {
                XCTAssertTrue(self.headerExists(requiredHeader, in: actual.headers.headers),
                              "Required Header:\(requiredHeader) does not exist in headers")
            }
            
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                self.assertEqualHttpBodyJSONData(expectedHttpBody!, actualHttpBody!) { (expectedData, actualData) in
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
            
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! MockOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<MockOutput, MockMiddlewareError>(httpResponse: response, output: mockOutput)
            deserializeMiddleware.fulfill()
            return .success(output)
           })
        
        let context = HttpContextBuilder().withEncoder(value: JSONEncoder()).build()
        _ = operationStack.handleMiddleware(context: context, input: input, next: MockHandler { (_, _) in
            XCTFail("Deserialize was mocked out, this should fail")
            return .failure(try! MockMiddlewareError(httpResponse: HttpResponse(body: .none, statusCode: .badRequest)))
        })
        
        wait(for: [deserializeMiddleware], timeout: 2.0)
    }        
}
