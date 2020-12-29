 // Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 // SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import ClientRuntime

class MiddlewareStackTests: XCTestCase {
    let context: HttpContextBuilder = HttpContextBuilder()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    func testMiddlewareStackSuccessInterceptAfter() {
        let builtContext = context.build()
        var stack = OperationStack<TestInput, TestOutput>(id: "Test Operation")
        stack.initializeStep.intercept(position: .after, middleware: TestSerializeMiddleware<TestInput>(id: "TestMiddleware"))
        stack.serializeStep.intercept(position: .after, id: "Serialize") { (context, sdkBuilder, next) -> Result<SdkHttpRequestBuilder, Error> in
            return next.handle(context: context, input: sdkBuilder)
        }
        stack.buildStep.intercept(position: .after, id: "Build") { (context, sdkBuilder, next) -> Result<SdkHttpRequestBuilder, Error> in
            return next.handle(context: context, input: sdkBuilder)
        }
        stack.finalizeStep.intercept(position: .after, id: "Finalize") { (context, sdkBuilder, next) -> Result<SdkHttpRequest, Error> in
            return next.handle(context: context, input: sdkBuilder)
        }
        stack.deserializeStep.intercept(position: .after, middleware: TestDeserializeMiddleware<TestOutput>(id: "TestDeserializeMiddleware"))
        let input = TestInput()
        
        let result = stack.handleMiddleware(context: builtContext, subject: input, next: TestHandler())
        
        switch result {
        case .success(let output):
            XCTAssert(output.value == 200)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testMiddlewareStackConvenienceFunction() {
        let builtContext = context.build()
        var stack = OperationStack<TestInput, TestOutput>(id: "Test Operation")
        stack.initializeStep.intercept(position: .before, id: "create http request") { (context, input, next) -> Result<SdkHttpRequestBuilder, Error> in
            
            return next.handle(context: context, input: input)
        }
        stack.serializeStep.intercept(position: .after, id: "Serialize") { (context, sdkBuilder, next) -> Result<SdkHttpRequestBuilder, Error> in
            return next.handle(context: context, input: sdkBuilder)
        }
        
        stack.buildStep.intercept(position: .before, id: "add a header") { (context, requestBuilder, next) -> Result<SdkHttpRequestBuilder, Error> in
            requestBuilder.headers.add(name: "Test", value: "Value")
            return next.handle(context: context, input: requestBuilder)
        }
        stack.finalizeStep.intercept(position: .after, id: "convert request builder to request") { (context, requestBuilder, next) -> Result<SdkHttpRequest, Error> in
            return .success(requestBuilder.build())
        }

        let input = TestInput()

        let result = stack.handleMiddleware(context: builtContext, subject: input, next: TestHandler())

        switch result {
        case .success(let output):
            XCTAssert(output.value == 200)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
}
 
 struct TestHandler: Handler {
    typealias Context = HttpContext
    
    func handle(context: Context, input: SdkHttpRequest) -> Result<HttpResponse, Error> {
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
    typealias Context = HttpContext
    
    typealias MOutput = SdkHttpRequestBuilder
    
    var id: String
    
    func handle<H>(context: HttpContext, input: MInput, next: H) -> Result<MOutput, Error> where H: Handler, Self.MInput == H.Input, Self.MOutput == H.Output, Self.Context == H.Context {
        var copiedInput = input
        let requestBuilder = try! copiedInput.buildHttpRequest(method: .get, path: "/", encoder: JSONEncoder())
        requestBuilder.headers.add(name: "Test", value: "Value")
        return next.handle(context: context, input: input)
    }
    
    typealias MInput = Input
    
 }
 
 struct TestDeserializeMiddleware<Output: HttpResponseBinding>: Middleware {
    var id: String
    
    func handle<H>(context: Context, input: SdkHttpRequest, next: H) -> Result<Output, Error> where H: Handler, Self.MInput == H.Input, Self.MOutput == H.Output {
        //mock client to fake return of request
        let httpResponse = HttpResponse(body: HttpBody.none, statusCode: HttpStatusCode.ok)
        let decoder = JSONDecoder()
        let output = try! Output(httpResponse: httpResponse, decoder: decoder)
        return .success(output)
        
    }
    
    typealias MInput = SdkHttpRequest
    
    typealias MOutput = Output
    typealias Context = HttpContext
    
    
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
