/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import SmithyReadWrite
import SmithyJSON
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

    struct SayHelloInputQueryItemMiddleware<StackOutput>: Middleware {

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

    struct SayHelloInputHeaderMiddleware<StackOutput>: Middleware {
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

    struct SayHelloInputBodyMiddleware<StackOutput>: Middleware {
        var id: String = "SayHelloInputBodyMiddleware"

        let rootNodeInfo: SmithyJSON.Writer.NodeInfo
        let inputWritingClosure: WritingClosure<SayHelloInput, SmithyJSON.Writer>

        public init(
            rootNodeInfo: SmithyJSON.Writer.NodeInfo,
            inputWritingClosure: @escaping WritingClosure<SayHelloInput, SmithyJSON.Writer>
        ) {
            self.rootNodeInfo = rootNodeInfo
            self.inputWritingClosure = inputWritingClosure
        }

        func handle<H>(
            context: HttpContext,
            input: MInput,
            next: H
        ) async throws -> MOutput where
            H: Handler,
            Self.Context == H.Context,
            Self.MInput == H.Input,
            Self.MOutput == H.Output {


            let writer = SmithyJSON.Writer(nodeInfo: rootNodeInfo)
            try writer.write(input.operationInput, with: inputWritingClosure)
            let body = ByteStream.data(try writer.data())
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

        init(greeting: String? = nil,
             forbiddenQuery: String? = nil,
             requiredQuery: String? = nil,
             forbiddenHeader: String? = nil,
             requiredHeader: String? = nil) {
            self.greeting = greeting
            self.forbiddenQuery = forbiddenQuery
            self.requiredQuery = requiredQuery
            self.forbiddenHeader = forbiddenHeader
            self.requiredHeader = requiredHeader
        }

        private enum CodingKeys: String, CodingKey {
            case greeting
        }

        static func write(value: SayHelloInput, to writer: SmithyJSON.Writer) throws {
            try writer["greeting"].write(value.greeting)
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
        operationStack.serializeStep.intercept(position: .before, middleware: SayHelloInputBodyMiddleware(rootNodeInfo: "", inputWritingClosure: SayHelloInput.write(value:to:)))
        operationStack.deserializeStep.intercept(position: .after, middleware: MockDeserializeMiddleware<MockOutput>(
            id: "TestDeserializeMiddleware", responseClosure: { _ in MockOutput() }) { _, actual in

            let forbiddenQueryParams = ["ForbiddenQuery"]
            for forbiddenQueryParam in forbiddenQueryParams {
                XCTAssertFalse(
                    self.queryItemExists(forbiddenQueryParam, in: actual.destination.queryItems),
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
                XCTAssertTrue(self.queryItemExists(requiredQueryParam, in: actual.destination.queryItems),
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
                try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, contentType: .json)
            })

            let response = HttpResponse(body: ByteStream.noStream, statusCode: .ok)
            let mockOutput = MockOutput()
            let output = OperationOutput<MockOutput>(httpResponse: response, output: mockOutput)
            return output
           })

        let context = HttpContextBuilder()
            .withMethod(value: .post)
            .build()
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler { (_, _) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .noStream, statusCode: .badRequest)
            let mockServiceError = MockMiddlewareError.responseErrorClosure(httpResponse)
            throw mockServiceError
        })
    }
}
