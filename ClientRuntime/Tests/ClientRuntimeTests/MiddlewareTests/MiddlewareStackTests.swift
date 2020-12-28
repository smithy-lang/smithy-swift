// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.
 
 import XCTest
 import Foundation
 @testable import ClientRuntime
 
 class MiddlewareStackTests: XCTestCase {
    let context: HttpContextBuilder = HttpContextBuilder()
    var httpClient: SdkHttpClient!
    
    override func setUp() {
        super.setUp()
        let httpClientConfiguration = HttpClientConfiguration()
        httpClient = try! SdkHttpClient(config: httpClientConfiguration)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testMiddlewareStackSuccessInterceptAfter() {
        let addContextValues = context
            .withMethod(value: .get)
            .withPath(value: "/")
            .withEncoder(value: JSONEncoder())
            .withDecoder(value: JSONDecoder())
            .withOperation(value: "Test Operation")
        let builtContext = addContextValues.build()
        var stack = OperationStack<TestInput, TestOutput, TestError>(id: "Test Operation")
        stack.serializeStep.intercept(position: .after, middleware: TestSerializeMiddleware(id: "TestMiddleware"))
        
        stack.deserializeStep.intercept(position: .after, middleware: TestDeserializeMiddleware<TestOutput, TestError>(id: "TestDeserializeMiddleware"))
        let input = TestInput()
        
        let result = stack.handleMiddleware(context: builtContext, input: input, next: TestHandler())
        
        switch result {
        case .success(let output):
            XCTAssert(output.value == 200)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testMiddlewareStackConvenienceFunction() {
        let addContextValues = context
            .withMethod(value: .get)
            .withPath(value: "/")
            .withEncoder(value: JSONEncoder())
            .withDecoder(value: JSONDecoder())
            .withOperation(value: "Test Operation")
        let builtContext = addContextValues.build()
        var stack = OperationStack<TestInput, TestOutput, TestError>(id: "Test Operation")
        stack.addDefaultOperationMiddlewares()
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
            return next.handle(context: context, input: requestBuilder)
        }
        
        let input = TestInput()
        
        let result = stack.handleMiddleware(context: builtContext, input: input, next: TestHandler())
        
        switch result {
        case .success(let output):
            XCTAssert(output.value == 200)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testFullBlownOperationRequestWithClientHandler() {
        let addContextValues = context
            .withMethod(value: .get)
            .withPath(value: "/headers")
            .withEncoder(value: JSONEncoder())
            .withDecoder(value: JSONDecoder())
            .withOperation(value: "Test Operation")
        let builtContext = addContextValues.build()
        var stack = OperationStack<TestInput, TestOutput, TestError>(id: "Test Operation")
        stack.serializeStep.intercept(position: .after, middleware: TestSerializeMiddleware(id: "TestMiddleware"))
        
        stack.deserializeStep.intercept(position: .after, middleware: TestDeserializeMiddleware<TestOutput, TestError>(id: "TestDeserializeMiddleware"))
        let input = TestInput()
        
        let result = stack.handleMiddleware(context: builtContext, input: input, next: httpClient.getHandler())
        
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
 
 struct TestHandler<Output: HttpResponseBinding, OutputError: HttpResponseBinding>: Handler where OutputError: Error {
    
    typealias Context = HttpContext
    
    func handle(context: Context, input: SdkHttpRequest) -> Result<DeserializeOutput<Output, OutputError>, Error> {
        XCTAssert(input.headers.value(for: "Test") == "Value")
        //we pretend made a request here to a mock client and are returning a 200 response
        let httpResponse = HttpResponse(body: HttpBody.none, statusCode: HttpStatusCode.ok)
        let output = DeserializeOutput<Output, OutputError>(httpResponse: httpResponse)

        return .success(output)
    }
    
    typealias Input = SdkHttpRequest
    
    typealias Output = DeserializeOutput<Output, OutputError>
 }
 
 struct TestSerializeMiddleware: Middleware {
    typealias Context = HttpContext
    
    typealias MOutput = SdkHttpRequestBuilder
    
    var id: String

    func handle<H>(context: HttpContext, input: MInput, next: H) -> Result<MOutput, Error> where H: Handler, Self.MInput == H.Input, Self.MOutput == H.Output, Self.Context == H.Context {
        input.withHost("httpbin.org")
        input.headers.add(name: "Content-type", value: "application/json")
        input.headers.add(name: "Test", value: "Value")
        return next.handle(context: context, input: input)
    }
    
    typealias MInput = SdkHttpRequestBuilder
 }
 
 struct TestDeserializeMiddleware<Output: HttpResponseBinding,
                                  OutputError: HttpResponseBinding>: Middleware where OutputError: Error{
    var id: String
    
    func handle<H>(context: Context, input: SdkHttpRequest, next: H) -> Result<DeserializeOutput<Output, OutputError>, Error>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
        //mock client to fake return of request
        let response = next.handle(context: context, input: input) //call handler to get fake response of http response
        do {
            let successResponse = try response.get()
            var copiedResponse = successResponse
            if let httpResponse = copiedResponse.httpResponse {
                let decoder = context.getDecoder()
                let output = try Output(httpResponse: httpResponse, decoder: decoder)
                copiedResponse.output = output
                
                return .success(copiedResponse)
            } else {
                return .failure(ClientError.unknownError("Http response was nil which should never happen"))
            }
        } catch let err {
            return .failure(ClientError.deserializationFailed(err))
        }
    }
    
    typealias MInput = SdkHttpRequest
    typealias MOutput = DeserializeOutput<Output, OutputError>
    typealias Context = HttpContext
 }
 
 struct TestInput: HttpRequestBinding {
    func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator) throws -> SdkHttpRequestBuilder {
        return SdkHttpRequestBuilder()
    }
 }
 
 struct TestOutput: HttpResponseBinding {
    let value: Int
    let headers: Headers
    init(httpResponse: HttpResponse, decoder: ResponseDecoder?) throws {
        self.value = httpResponse.statusCode.rawValue
        self.headers = httpResponse.headers
    }
 }
 
 public enum TestError: Error {
    case unknown(Error)
 }
 extension TestError: HttpResponseBinding {
    public init(httpResponse: HttpResponse, decoder: ResponseDecoder? = nil) throws {
        try self.init(httpResponse: httpResponse)
    }
 }

