//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
import XCTest
@testable import ClientRuntime
import SmithyTestUtil

class MutateHeaderMiddlewareTests: XCTestCase {
    func testOverridesHeaders() {
        let httpClientConfiguration = HttpClientConfiguration()
        let clientEngine = MockHttpClientEngine()
        let httpClient = SdkHttpClient(engine: clientEngine, config: httpClientConfiguration)

        let builtContext = HttpContextBuilder()
            .withMethod(value: .get)
            .withPath(value: "/headers")
            .withEncoder(value: JSONEncoder())
            .withDecoder(value: JSONDecoder())
            .withOperation(value: "Test Operation")
            .build()
        var stack = OperationStack<MockInput, MockOutput, MockMiddlewareError>(id: "Test Operation")
        stack.buildStep.intercept(position: .before, id: "AddHeaders") { (context, input, next) -> Result<OperationOutput<MockOutput>, SdkError<MockMiddlewareError>> in
            input.withHeader(name: "foo", value: "bar")
            input.withHeader(name: "baz", value: "qux")
            return next.handle(context: context, input: input)
        }
        stack.buildStep.intercept(position: .after, middleware: MutateHeadersMiddleware(overrides: ["foo": "override"], additional: ["z": "zebra"]))
        stack.serializeStep.intercept(position: .after,
                                      middleware: MockSerializeMiddleware(id: "TestMiddleware", headerName: "TestName", headerValue: "TestValue"))
        stack.deserializeStep.intercept(position: .after,
                                        middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(id: "TestDeserializeMiddleware"))
        
        let result = stack.handleMiddleware(context: builtContext, input: MockInput(), next: httpClient.getHandler())
        
        switch result {
        case .success(let output):
            let fooHeader = output.headers.value(for: "foo")
            let zHeader = output.headers.value(for: "z")
            let bazHeader = output.headers.value(for: "baz")
            XCTAssertEqual(fooHeader, "override")
            XCTAssertEqual(zHeader, "zebra")
            XCTAssertEqual(bazHeader, "qux")
            
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testAppendsHeaders() {
        let httpClientConfiguration = HttpClientConfiguration()
        let clientEngine = MockHttpClientEngine()
        let httpClient = SdkHttpClient(engine: clientEngine, config: httpClientConfiguration)

        let builtContext = HttpContextBuilder()
            .withMethod(value: .get)
            .withPath(value: "/headers")
            .withEncoder(value: JSONEncoder())
            .withDecoder(value: JSONDecoder())
            .withOperation(value: "Test Operation")
            .build()
        var stack = OperationStack<MockInput, MockOutput, MockMiddlewareError>(id: "Test Operation")
        stack.buildStep.intercept(position: .before, id: "AddHeaders") { (context, input, next) -> Result<OperationOutput<MockOutput>, SdkError<MockMiddlewareError>> in
            input.withHeader(name: "foo", value: "bar")
            input.withHeader(name: "baz", value: "qux")
            return next.handle(context: context, input: input)
        }
        stack.buildStep.intercept(position: .before, middleware: MutateHeadersMiddleware(additional: ["foo": "appended", "z": "zebra"]))
        stack.serializeStep.intercept(position: .after,
                                      middleware: MockSerializeMiddleware(id: "TestMiddleware", headerName: "TestName", headerValue: "TestValue"))
        stack.deserializeStep.intercept(position: .after,
                                        middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(id: "TestDeserializeMiddleware"))
        
        let result = stack.handleMiddleware(context: builtContext, input: MockInput(), next: httpClient.getHandler())
        
        switch result {
        case .success(let output):
            let fooHeader = output.headers.values(for: "foo")
            let zHeader = output.headers.value(for: "z")
            let bazHeader = output.headers.value(for: "baz")
           
            XCTAssertEqual(fooHeader, ["appended", "bar"])
            XCTAssertEqual(zHeader, "zebra")
            XCTAssertEqual(bazHeader, "qux")
            
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testConditionallySetHeaders() {
        let httpClientConfiguration = HttpClientConfiguration()
        let clientEngine = MockHttpClientEngine()
        let httpClient = SdkHttpClient(engine: clientEngine, config: httpClientConfiguration)

        let builtContext = HttpContextBuilder()
            .withMethod(value: .get)
            .withPath(value: "/headers")
            .withEncoder(value: JSONEncoder())
            .withDecoder(value: JSONDecoder())
            .withOperation(value: "Test Operation")
            .build()
        var stack = OperationStack<MockInput, MockOutput, MockMiddlewareError>(id: "Test Operation")
        stack.buildStep.intercept(position: .before, id: "AddHeaders") { (context, input, next) -> Result<OperationOutput<MockOutput>, SdkError<MockMiddlewareError>> in
            input.withHeader(name: "foo", value: "bar")
            input.withHeader(name: "baz", value: "qux")
            return next.handle(context: context, input: input)
        }
        stack.buildStep.intercept(position: .after, middleware: MutateHeadersMiddleware(conditionallySet: ["foo": "nope", "z": "zebra"]))
        stack.serializeStep.intercept(position: .after,
                                      middleware: MockSerializeMiddleware(id: "TestMiddleware", headerName: "TestName", headerValue: "TestValue"))
        stack.deserializeStep.intercept(position: .after,
                                        middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(id: "TestDeserializeMiddleware"))
        
        let result = stack.handleMiddleware(context: builtContext, input: MockInput(), next: httpClient.getHandler())
        
        switch result {
        case .success(let output):
            let fooHeader = output.headers.value(for: "foo")
            let zHeader = output.headers.value(for: "z")
            let bazHeader = output.headers.value(for: "baz")
           
            XCTAssertEqual(fooHeader, "bar")
            XCTAssertEqual(zHeader, "zebra")
            XCTAssertEqual(bazHeader, "qux")
            
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
}
