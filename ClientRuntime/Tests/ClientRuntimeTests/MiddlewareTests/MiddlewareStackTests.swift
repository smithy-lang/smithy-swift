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
        let initializeStep = InitializeStep()
        let serializeStep = SerializeStep()
        let buildStep = BuildStep()
        let finalizeStep = FinalizeStep()
        let deserializeStep = DeserializeStep()
        let context = TestContext()
        var stack = OperationStack<TestInput, TestOutput>(id: "Test Operation",
                                   initializeStep: initializeStep,
                                   serializeStep: serializeStep,
                                   buildStep: buildStep,
                                   finalizeStep: finalizeStep,
                                   deserializeStep: deserializeStep)
        stack.initializeStep.intercept(position: .before, middleware: TestMiddleware(id: "TestMiddleware"))

        let result = stack.handleMiddleware(context: context, subject: TestInput(), next: TestHandler<TestInput, TestOutput>())
        
        switch result {
        case .success(let output):
            XCTAssert(output.value == 200)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testMiddlewareStackConvenienceFunction() {
        let initializeStep = InitializeStep()
        let serializeStep = SerializeStep()
        let buildStep = BuildStep()
        let finalizeStep = FinalizeStep()
        let deserializeStep = DeserializeStep()
        let context = TestContext()
        var stack = OperationStack<TestInput, TestOutput>(id: "Test Operation",
                                   initializeStep: initializeStep,
                                   serializeStep: serializeStep,
                                   buildStep: buildStep,
                                   finalizeStep: finalizeStep,
                                   deserializeStep: deserializeStep)
        stack.initializeStep.intercept(position: .before, id: "add a header") { (context, input) -> Result<Any, Error> in
            let inputCasted = (input as? SdkHttpRequest ?? SdkHttpRequest(method: .get, endpoint: Endpoint(host: "/"), headers: Headers()))
            inputCasted.headers.add(name: "Test", value: "Value")
            
            return .success(inputCasted)
        }

        let result = stack.handleMiddleware(context: context, subject: TestInput(), next: TestHandler())
        
        switch result {
        case .success(let output):
            XCTAssert(output.value == 200)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
}
 
 struct TestHandler<Input: HttpRequestBinding, Output: HttpResponseBinding>: Handler {
    
    func handle(context: MiddlewareContext, input: Input) -> Result<Output, Error> {
        let httpResponse = HttpResponse(body: HttpBody.none, statusCode: HttpStatusCode.accepted)
        let decoder = JSONDecoder()
        let output = try! Output(httpResponse: httpResponse, decoder: decoder)
        return .success(output)
    }
    
    typealias Input = Input
    
    typealias Output = Output
    
    
 }
 
 struct TestMiddleware: Middleware {
    var id: String
    
    func handle<H>(context: MiddlewareContext, input: Any, next: H) -> Result<Any, Error> where H : Handler, Self.MInput == H.Input, Self.MOutput == H.Output {
        let inputCasted = (input as? SdkHttpRequest ?? SdkHttpRequest(method: .get, endpoint: Endpoint(host: "/"), headers: Headers()))
        inputCasted.headers.add(name: "Test", value: "Value")
        
        return next.handle(context: context, input: inputCasted)
    }
    
    typealias MInput = Any
    
    typealias MOutput = Any
    
    
 }

 struct TestContext: MiddlewareContext {
    var attributes: Attributes = Attributes()
 }

 struct TestInput: HttpRequestBinding {
    mutating func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder) throws -> SdkHttpRequest {
        return SdkHttpRequest(method: method, endpoint: Endpoint(host: path), headers: Headers())
    }
    
    
 }

 struct TestOutput: HttpResponseBinding {
    let value: Int
    init(httpResponse: HttpResponse, decoder: ResponseDecoder?) throws {
        self.value = httpResponse.statusCode.rawValue
    }
 }
