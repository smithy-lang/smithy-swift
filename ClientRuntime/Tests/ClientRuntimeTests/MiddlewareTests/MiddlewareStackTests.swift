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
        let addContextValues = context
            .withMethod(value: .get)
            .withPath(value: "/")
            .withEncoder(value: JSONEncoder())
            .withDecoder(value: JSONDecoder())
            .withOperation(value: "Test Operation")
        let builtContext = addContextValues.build()
        var stack = OperationStack<TestInput, TestOutput>(id: "Test Operation")
        stack.serializeStep.intercept(position: .after, middleware: TestSerializeMiddleware(id: "TestMiddleware"))
        
        stack.deserializeStep.intercept(position: .after, middleware: TestDeserializeMiddleware<TestOutput>(id: "TestDeserializeMiddleware"))
        let input = TestInput()
        
        let result = stack.handleMiddleware(context: builtContext, subject: input, next: TestHandler())
        
        switch result {
        case .success(let output):
            XCTAssert(output.output?.value == 200)
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
            return next.handle(context: context, input: requestBuilder)
        }
        
        let input = TestInput()
        
        let result = stack.handleMiddleware(context: builtContext, subject: input, next: TestHandler())
        
        switch result {
        case .success(let output):
            XCTAssert(output.output?.value == 200)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
 }
 
 struct TestHandler<Output: HttpResponseBinding>: Handler {
    typealias Context = HttpContext
    
    func handle(context: Context, input: SdkHttpRequest) -> Result<DeserializeOutput<Output>, Error> {
        XCTAssert(input.headers.value(for: "Test") == "Value")
        //we pretend made a request here to a mock client and are returning a 200 response
        let httpResponse = HttpResponse(body: HttpBody.none, statusCode: HttpStatusCode.ok)
        let output = DeserializeOutput<Output>(httpResponse: httpResponse)
        return .success(output)
    }
    
    typealias Input = SdkHttpRequest
    
    typealias Output = DeserializeOutput<Output>
 }
 
 struct TestSerializeMiddleware: Middleware {
    typealias Context = HttpContext
    
    typealias MOutput = SdkHttpRequestBuilder
    
    var id: String
    
    func handle<H>(context: HttpContext, input: MInput, next: H) -> Result<MOutput, Error> where H: Handler, Self.MInput == H.Input, Self.MOutput == H.Output, Self.Context == H.Context {
        
        input.headers.add(name: "Test", value: "Value")
        return next.handle(context: context, input: input)
    }
    
    typealias MInput = SdkHttpRequestBuilder
 }
 
 struct TestDeserializeMiddleware<Output: HttpResponseBinding>: Middleware {
    var id: String
    
    func handle<H>(context: Context, input: SdkHttpRequest, next: H) -> Result<DeserializeOutput<Output>, Error> where H: Handler,
                                                                                                                       Self.MInput == H.Input,
                                                                                                                       Self.MOutput == H.Output,
                                                                                                                       Self.Context == H.Context {
        //mock client to fake return of request
        let response = next.handle(context: context, input: input) //call handler to get fake response of http response
        do {
            let successResponse = try response.get()
            var copiedResponse = successResponse
            if let httpResponse = successResponse.httpResponse {
                let decoder = JSONDecoder()
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
    typealias MOutput = DeserializeOutput<Output>
    typealias Context = HttpContext
 }
 
 struct TestInput: HttpRequestBinding {
    func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator) throws -> SdkHttpRequestBuilder {
        return SdkHttpRequestBuilder()
    }
 }
 
 struct TestOutput: HttpResponseBinding {
    let value: Int
    init(httpResponse: HttpResponse, decoder: ResponseDecoder?) throws {
        self.value = httpResponse.statusCode.rawValue
    }
 }
