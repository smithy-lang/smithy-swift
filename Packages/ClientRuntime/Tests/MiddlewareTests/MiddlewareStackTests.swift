// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import XCTest
import SmithyTestUtil
@testable import ClientRuntime

class MiddlewareStackTests: XCTestCase {
    func testMiddlewareStackSuccessInterceptAfter() {
        let builtContext = HttpContextBuilder()
            .withMethod(value: .get)
            .withPath(value: "/")
            .withEncoder(value: JSONEncoder())
            .withDecoder(value: JSONDecoder())
            .withOperation(value: "Test Operation")
            .build()
        var stack = OperationStack<MockInput, MockOutput, MockMiddlewareError>(id: "Test Operation")
        stack.serializeStep.intercept(position: .after,
                                      middleware: MockSerializeMiddleware(id: "TestMiddleware", headerName: "TestHeaderName1", headerValue: "TestHeaderValue1"))
        stack.deserializeStep.intercept(position: .after,
                                        middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(id: "TestDeserializeMiddleware"))
        
        let result = stack.handleMiddleware(context: builtContext, input: MockInput(),
                                            next: MockHandler(handleCallback: { (_, input) in
                                                XCTAssert(input.headers.value(for: "TestHeaderName1") == "TestHeaderValue1")
                                                let httpResponse = HttpResponse(body: HttpBody.none, statusCode: HttpStatusCode.ok)
                                                let output = OperationOutput<MockOutput, MockMiddlewareError>(httpResponse: httpResponse)
                                                return .success(output)
                                            }))
        
        switch result {
        case .success(let output):
            XCTAssert(output.value == 200)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testMiddlewareStackConvenienceFunction() {
        let builtContext = HttpContextBuilder()
            .withMethod(value: .get)
            .withPath(value: "/")
            .withEncoder(value: JSONEncoder())
            .withDecoder(value: JSONDecoder())
            .withOperation(value: "Test Operation")
            .build()
        var stack = OperationStack<MockInput, MockOutput, MockMiddlewareError>(id: "Test Operation")
        stack.addDefaultOperationMiddlewares()
        stack.initializeStep.intercept(position: .before, id: "create http request") { (context, input, next) -> Result<OperationOutput<MockOutput, MockMiddlewareError>, Error> in
            
            return next.handle(context: context, input: input)
        }
        stack.serializeStep.intercept(position: .after, id: "Serialize") { (context, input, next) -> Result<OperationOutput<MockOutput, MockMiddlewareError>, Error> in
            return next.handle(context: context, input: input)
        }

        stack.buildStep.intercept(position: .before, id: "add a header") { (context, input, next) -> Result<OperationOutput<MockOutput, MockMiddlewareError>, Error> in
            input.headers.add(name: "TestHeaderName2", value: "TestHeaderValue2")
            return next.handle(context: context, input: input)
        }
        stack.finalizeStep.intercept(position: .after, id: "convert request builder to request") { (context, requestBuilder, next) -> Result<OperationOutput<MockOutput, MockMiddlewareError>, Error> in
            return next.handle(context: context, input: requestBuilder)
        }
        
        let result = stack.handleMiddleware(context: builtContext, input: MockInput(),
                                            next: MockHandler(handleCallback: { (_, input) in
                                                XCTAssert(input.headers.value(for: "TestHeaderName2") == "TestHeaderValue2")
                                                let httpResponse = HttpResponse(body: HttpBody.none, statusCode: HttpStatusCode.ok)
                                                let output = OperationOutput<MockOutput, MockMiddlewareError>(httpResponse: httpResponse)
                                                return .success(output)
                                            }))
        
        switch result {
        case .success(let output):
            XCTAssert(output.value == 200)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testFullBlownOperationRequestWithClientHandler() {
        let httpClientConfiguration = HttpClientConfiguration()
        let httpClient = try! SdkHttpClient(config: httpClientConfiguration)

        let builtContext = HttpContextBuilder()
            .withMethod(value: .get)
            .withPath(value: "/headers")
            .withEncoder(value: JSONEncoder())
            .withDecoder(value: JSONDecoder())
            .withOperation(value: "Test Operation")
            .build()
        var stack = OperationStack<MockInput, MockOutput, MockMiddlewareError>(id: "Test Operation")
        stack.serializeStep.intercept(position: .after,
                                      middleware: MockSerializeMiddleware(id: "TestMiddleware", headerName: "TestName", headerValue: "TestValue"))
        stack.deserializeStep.intercept(position: .after,
                                        middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(id: "TestDeserializeMiddleware"))
        
        let result = stack.handleMiddleware(context: builtContext, input: MockInput(), next: httpClient.getHandler())
        
        switch result {
        case .success(let output):
            XCTAssert(output.value == 200)
            XCTAssert(output.headers.headers.contains(where: { (header) -> Bool in
                header.name == "Content-Length"
            }))
            
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
}
