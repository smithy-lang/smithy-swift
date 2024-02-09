// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import XCTest
import SmithyTestUtil
@testable import ClientRuntime

class MiddlewareStackTests: XCTestCase {
    func testMiddlewareStackSuccessInterceptAfter() async throws {
        let builtContext = HttpContextBuilder()
            .withMethod(value: .get)
            .withPath(value: "/")
            .withEncoder(value: JSONEncoder())
            .withDecoder(value: JSONDecoder())
            .withOperation(value: "Test Operation")
            .build()
        var stack = OperationStack<MockInput, MockOutput>(id: "Test Operation")
        stack.serializeStep.intercept(position: .after,
                                      middleware: MockSerializeMiddleware(id: "TestMiddleware", headerName: "TestHeaderName1", headerValue: "TestHeaderValue1"))
        stack.deserializeStep.intercept(position: .after,
                                        middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(id: "TestDeserializeMiddleware"))

        let result = try await stack.handleMiddleware(context: builtContext, input: MockInput(),
                                            next: MockHandler(handleCallback: { (_, input) in
                                                XCTAssert(input.headers.value(for: "TestHeaderName1") == "TestHeaderValue1")
                                                let httpResponse = HttpResponse(body: ByteStream.noStream, statusCode: HttpStatusCode.ok)
                                                let mockOutput = try! await MockOutput(httpResponse: httpResponse, decoder: nil)
                                                let output = OperationOutput<MockOutput>(httpResponse: httpResponse,
                                                                                         output: mockOutput)
                                                return output
                                            }))
        XCTAssert(result.value == 200)
    }

    func testMiddlewareStackConvenienceFunction() async throws {
        let builtContext = HttpContextBuilder()
            .withMethod(value: .get)
            .withPath(value: "/")
            .withEncoder(value: JSONEncoder())
            .withDecoder(value: JSONDecoder())
            .withOperation(value: "Test Operation")
            .build()
        var stack = OperationStack<MockInput, MockOutput>(id: "Test Operation")
        stack.initializeStep.intercept(position: .before, id: "create http request") { (context, input, next) -> OperationOutput<MockOutput> in

            return try await next.handle(context: context, input: input)
        }
        stack.serializeStep.intercept(position: .after, id: "Serialize") { (context, input, next) -> OperationOutput<MockOutput> in
            return try await next.handle(context: context, input: input)
        }

        stack.buildStep.intercept(position: .before, id: "add a header") { (context, input, next) -> OperationOutput<MockOutput> in
            input.headers.add(name: "TestHeaderName2", value: "TestHeaderValue2")
            return try await next.handle(context: context, input: input)
        }
        stack.finalizeStep.intercept(position: .after, id: "convert request builder to request") { (context, requestBuilder, next) -> OperationOutput<MockOutput> in
            return try await next.handle(context: context, input: requestBuilder)
        }
        stack.finalizeStep.intercept(position: .before, middleware: ContentLengthMiddleware())
        stack.deserializeStep.intercept(position: .after, middleware: DeserializeMiddleware<MockOutput>(responseClosure(decoder: JSONDecoder()), responseErrorClosure(MockMiddlewareError.self, decoder: JSONDecoder())))
        let result = try await stack.handleMiddleware(context: builtContext, input: MockInput(),
                                            next: MockHandler(handleCallback: { (_, input) in
                                                XCTAssert(input.headers.value(for: "TestHeaderName2") == "TestHeaderValue2")
                                                let httpResponse = HttpResponse(body: ByteStream.noStream, statusCode: HttpStatusCode.ok)
                                                let mockOutput = try! await MockOutput(httpResponse: httpResponse, decoder: nil)
                                                let output = OperationOutput<MockOutput>(httpResponse: httpResponse,
                                                                                         output: mockOutput)
                                                return output
                                            }))

        XCTAssert(result.value == 200)
    }

    // This test is disabled because unreliability of httpbin.org is causing spurious failures.
    // Github issue to track correction of these tests: https://github.com/awslabs/aws-sdk-swift/issues/962

    func xtestFullBlownOperationRequestWithClientHandler() async throws {
        let httpClientConfiguration = HttpClientConfiguration()
        let clientEngine = CRTClientEngine()
        let httpClient = SdkHttpClient(engine: clientEngine, config: httpClientConfiguration)

        let builtContext = HttpContextBuilder()
            .withMethod(value: .get)
            .withPath(value: "/headers")
            .withEncoder(value: JSONEncoder())
            .withDecoder(value: JSONDecoder())
            .withOperation(value: "Test Operation")
            .build()
        var stack = OperationStack<MockInput, MockOutput>(id: "Test Operation")
        stack.serializeStep.intercept(position: .after,
                                      middleware: MockSerializeMiddleware(id: "TestMiddleware", headerName: "TestName", headerValue: "TestValue"))
        stack.deserializeStep.intercept(position: .after,
                                        middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(id: "TestDeserializeMiddleware"))

        let result = try await stack.handleMiddleware(context: builtContext, input: MockInput(), next: httpClient.getHandler())

        XCTAssert(result.value == 200)
        XCTAssert(result.headers.headers.contains(where: { (header) -> Bool in
            header.name == "Content-Length"
        }))
    }
}
