/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import SmithyTestUtil
import ClientRuntime
import XCTest

class HttpRequestTestBaseTests: HttpRequestTestBase {
    static let host = "myapi.host.com"

    public struct SayHelloInputURLHostMiddleware: ClientRuntime.Middleware {
        public let id: Swift.String = "SayHelloInputURLHostMiddleware"

        let host: Swift.String?

        public init(host: Swift.String? = nil) {
            self.host = host
        }

        public func handle<H>(context: Context,
                      input: SayHelloInput,
                      next: H) async throws -> ClientRuntime.OperationOutput<MockOutput>
        where H: Handler,
        Self.MInput == H.Input,
        Self.MOutput == H.Output,
        Self.Context == H.Context
        {
            if let host = host {
                context.attributes.set(key: AttributeKey<String>(name: "Host"), value: host)
            }
            return try await next.handle(context: context, input: input)
        }

        public typealias MInput = SayHelloInput
        public typealias MOutput = ClientRuntime.OperationOutput<MockOutput>
        public typealias Context = ClientRuntime.HttpContext
    }

    struct SayHelloInputQueryItemMiddleware<StackOutput: HttpResponseBinding>: Middleware {

        var id: String = "SayHelloInputQueryItemMiddleware"

        func handle<H>(context: HttpContext,
                       input: SerializeStepInput<SayHelloInput>,
                       next: H) async throws -> MOutput where H: Handler,
                                                                Self.Context == H.Context,
                                                                Self.MInput == H.Input,
                                                                Self.MOutput == H.Output {
            var queryItems: [SDKURLQueryItem] = []
            var queryItem: SDKURLQueryItem
            if let requiredQuery = input.operationInput.requiredQuery {
                queryItem = SDKURLQueryItem(name: "RequiredQuery".urlPercentEncoding(), value: String(requiredQuery).urlPercentEncoding())
                queryItems.append(queryItem)
            }

            input.builder.withQueryItems(queryItems)
            return try await next.handle(context: context, input: input)
        }

        typealias MInput = SerializeStepInput<SayHelloInput>

        typealias MOutput = OperationOutput<StackOutput>

        typealias Context = HttpContext
    }

    struct SayHelloInputHeaderMiddleware<StackOutput: HttpResponseBinding>: Middleware {
        var id: String = "SayHelloInputHeaderMiddleware"

        func handle<H>(context: HttpContext,
                       input: MInput,
                       next: H) async throws -> MOutput where H: Handler,
                                                                Self.Context == H.Context,
                                                                Self.MInput == H.Input,
                                                                Self.MOutput == H.Output {
            var headers = Headers()
            headers.add(name: "Content-Type", value: "application/json")
            if let requiredHeader = input.operationInput.requiredHeader {
                headers.add(name: "RequiredHeader", value: requiredHeader)
            }
            input.builder.withHeaders(headers)
            return try await next.handle(context: context, input: input)
        }

        typealias MInput = SerializeStepInput<SayHelloInput>

        typealias MOutput = OperationOutput<StackOutput>

        typealias Context = HttpContext
    }

    struct SayHelloInputBodyMiddleware<StackOutput: HttpResponseBinding>: Middleware {
        var id: String = "SayHelloInputBodyMiddleware"

        func handle<H>(context: HttpContext,
                       input: MInput,
                       next: H) async throws -> MOutput where H: Handler,
                                                                Self.Context == H.Context,
                                                                Self.MInput == H.Input,
                                                                Self.MOutput == H.Output {

            let encoder = context.getEncoder()
            let body = ByteStream.data(try encoder.encode(input.operationInput))
            input.builder.withBody(body)
            return try await next.handle(context: context, input: input)

        }

        typealias MInput = SerializeStepInput<SayHelloInput>

        typealias MOutput = OperationOutput<StackOutput>

        typealias Context = HttpContext
    }

    struct SayHelloInput: Encodable {

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
    func testSayHello() async throws {
        let expected = buildExpectedHttpRequest(method: .post,
                                                path: "/",
                                                headers: ["Content-Type": "application/json",
                                                          "RequiredHeader": "required header"],
                                                requiredQueryParams: ["RequiredQuery=required%20query"],
                                                body: .data("{\"greeting\": \"Hello There\"}".data(using: .utf8)!),
                                                host: HttpRequestTestBaseTests.host,
                                                resolvedHost: nil)

        let input = SayHelloInput(greeting: "Hello There",
                                  forbiddenQuery: "forbidden query",
                                  requiredQuery: "required query",
                                  forbiddenHeader: "forbidden header",
                                  requiredHeader: "required header")

        var operationStack = OperationStack<SayHelloInput, MockOutput>(id: "SayHelloInputRequest")
        operationStack.initializeStep.intercept(position: .before, middleware: SayHelloInputURLHostMiddleware(host: HttpRequestTestBaseTests.host))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<MockOutput> in
            input.withMethod(context.getMethod())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
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

            try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) throws -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual ByteStream is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected ByteStream is nil")
                try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, isXML: false, isJSON: true) { (expectedData, actualData) in
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

            let response = HttpResponse(body: ByteStream.noStream, statusCode: .ok)
            let mockOutput = try! await MockOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<MockOutput>(httpResponse: response, output: mockOutput)
            return output
           })

        let context = HttpContextBuilder()
            .withEncoder(value: JSONEncoder())
            .withMethod(value: .post)
            .build()
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler { (_, _) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .noStream, statusCode: .badRequest)
            let mockServiceError = try await MockMiddlewareError.makeError(httpResponse: httpResponse, decoder: context.getDecoder())
            throw mockServiceError
        })
    }
}
