//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import XCTest
@testable import ClientRuntime
import SmithyTestUtil

class MutateHeaderMiddlewareTests: XCTestCase {
    var httpClientConfiguration: HttpClientConfiguration! = nil
    var clientEngine: MockHttpClientEngine! = nil
    var httpClient: SdkHttpClient! = nil
    var builtContext: Context! = nil
    var stack: OperationStack<MockInput, MockOutput>! = nil
    override func setUp() {
        httpClientConfiguration = HttpClientConfiguration()
        clientEngine = MockHttpClientEngine()
        httpClient = SdkHttpClient(engine: clientEngine, config: httpClientConfiguration)
        builtContext = ContextBuilder()
            .withMethod(value: .get)
            .withPath(value: "/headers")
            .withOperation(value: "Test Operation")
            .build()
        stack = OperationStack<MockInput, MockOutput>(id: "Test Operation")
        stack.serializeStep.intercept(position: .after,
                                      middleware: MockSerializeMiddleware(id: "TestMiddleware", headerName: "TestName", headerValue: "TestValue"))
        stack.deserializeStep.intercept(position: .after,
                                        middleware: MockDeserializeMiddleware<MockOutput>(id: "TestDeserializeMiddleware", responseClosure: MockOutput.responseClosure(_:)))
    }

    func testOverridesHeaders() async throws {
        stack.buildStep.intercept(position: .before, id: "AddHeaders") { (context, input, next) -> OperationOutput<MockOutput> in
            input.withHeader(name: "foo", value: "bar")
            input.withHeader(name: "baz", value: "qux")
            return try await next.handle(context: context, input: input)
        }
        stack.buildStep.intercept(position: .after, middleware: MutateHeadersMiddleware<MockInput, MockOutput>(overrides: ["foo": "override"], additional: ["z": "zebra"]))

        let output = try await stack.handleMiddleware(context: builtContext, input: MockInput(), next: httpClient.getHandler())

        XCTAssertEqual(output.headers.value(for: "foo"), "override")
        XCTAssertEqual(output.headers.value(for: "z"), "zebra")
        XCTAssertEqual(output.headers.value(for: "baz"), "qux")
    }

    func testAppendsHeaders() async throws {
        stack.buildStep.intercept(position: .before, id: "AddHeaders") { (context, input, next) -> OperationOutput<MockOutput> in
            input.withHeader(name: "foo", value: "bar")
            input.withHeader(name: "baz", value: "qux")
            return try await next.handle(context: context, input: input)
        }
        stack.buildStep.intercept(position: .before, middleware: MutateHeadersMiddleware<MockInput, MockOutput>(additional: ["foo": "appended", "z": "zebra"]))

        let output = try await stack.handleMiddleware(context: builtContext, input: MockInput(), next: httpClient.getHandler())

        XCTAssertEqual(output.headers.values(for: "foo"), ["appended", "bar"])
        XCTAssertEqual(output.headers.value(for: "z"), "zebra")
        XCTAssertEqual(output.headers.value(for: "baz"), "qux")
    }

    func testConditionallySetHeaders() async throws {
        stack.buildStep.intercept(position: .before, id: "AddHeaders") { (context, input, next) -> OperationOutput<MockOutput> in
            input.withHeader(name: "foo", value: "bar")
            input.withHeader(name: "baz", value: "qux")
            return try await next.handle(context: context, input: input)
        }
        stack.buildStep.intercept(position: .after, middleware: MutateHeadersMiddleware<MockInput, MockOutput>(conditionallySet: ["foo": "nope", "z": "zebra"]))

        let output = try await stack.handleMiddleware(context: builtContext, input: MockInput(), next: httpClient.getHandler())

        XCTAssertEqual(output.headers.value(for: "foo"), "bar")
        XCTAssertEqual(output.headers.value(for: "z"), "zebra")
        XCTAssertEqual(output.headers.value(for: "baz"), "qux")
    }
}
