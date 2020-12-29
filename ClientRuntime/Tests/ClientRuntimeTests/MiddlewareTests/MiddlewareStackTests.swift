 // Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 // SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import ClientRuntime

class MiddlewareStackTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    func testMiddlewareStackSuccessInterceptAfter() {
        let context = TestContext()
        var stack = OperationStack<TestInput, TestOutput>(id: "Test Operation")
        stack.initializeStep.intercept(position: .after, middleware: TestSerializeMiddleware<TestInput>(id: "TestMiddleware"))
        var input = TestInput()
        let sdkRequest = try! input.buildHttpRequest(method: .get, path: "/", encoder: JSONEncoder())
        let result = stack.handleMiddleware(context: context, subject: input, next: TestHandler())
        
        switch result {
        case .success(let output):
            XCTAssert(output.value == 200)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testMiddlewareStackConvenienceFunction() {
        let context = TestContext()
        var stack = OperationStack<TestInput, TestOutput>(id: "Test Operation")
        stack.initializeStep.intercept(position: .before, id: "create http request") { (context, input, next) -> Result<SdkHttpRequestBuilder, Error> in
            
            return next.handle(context: context, input: input)
        }
        
        stack.buildStep.intercept(position: .before, id: "add a header") { (context, requestBuilder, next) -> Result<SdkHttpRequestBuilder, Error> in
            requestBuilder.headers.add(name: "Test", value: "Value")
            return next.handle(context: context, input: requestBuilder)
        }
        stack.finalizeStep.intercept(position: .after, id: "convert request builder to request") { (context, requestBuilder, next) -> Result<SdkHttpRequest, Error> in
            return .success(requestBuilder.build())
        }

        let input = TestInput()
        //let request = try! input.buildHttpRequest(method: .get, path: "/", encoder: JSONEncoder())

        let result = stack.handleMiddleware(context: context, subject: input, next: TestHandler())

        switch result {
        case .success(let output):
            XCTAssert(output.value == 200)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
}
 
 struct TestHandler: Handler {
    
    func handle(context: MiddlewareContext, input: SdkHttpRequest) -> Result<HttpResponse, Error> {
        XCTAssert(input.headers.value(for: "Test") == "Value")
        let httpResponse = HttpResponse(body: HttpBody.none, statusCode: HttpStatusCode.ok)
//        let decoder = JSONDecoder()
//        let output = try! Output(httpResponse: httpResponse, decoder: decoder)
        return .success(httpResponse)
    }
    
    typealias Input = SdkHttpRequest
    
    typealias Output = HttpResponse
    
    
 }
 
 struct TestSerializeMiddleware<Input: HttpRequestBinding>: Middleware {
    
    typealias MOutput = SdkHttpRequestBuilder
    
    var id: String
    
    func handle<H>(context: MiddlewareContext, input: MInput, next: H) -> Result<MOutput, Error> where H : Handler, Self.MInput == H.Input, Self.MOutput == H.Output {
        var copiedInput = input
        let requestBuilder = try! copiedInput.buildHttpRequest(method: .get, path: "/", encoder: JSONEncoder())
        requestBuilder.headers.add(name: "Test", value: "Value")
        return .success(requestBuilder)
    }
    
    typealias MInput = Input
    
 }

 struct TestContext: MiddlewareContext {
    var attributes: Attributes = Attributes()
 }

 struct TestInput: HttpRequestBinding {
    mutating func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder) throws -> SdkHttpRequestBuilder {
        return SdkHttpRequestBuilder()
    }
    
    
 }

 struct TestOutput: HttpResponseBinding {
    let value: Int
    init(httpResponse: HttpResponse, decoder: ResponseDecoder?) throws {
        self.value = httpResponse.statusCode.rawValue
    }
 }
