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
        var stack = OperationStack<TestOutput>(id: "Test Operation")
        stack.initializeStep.intercept(position: .before, middleware: TestMiddleware(id: "TestMiddleware"))
        var input = TestInput()
        let sdkRequest = try! input.buildHttpRequest(method: .get, path: "/", encoder: JSONEncoder())
        let result = stack.handleMiddleware(context: context, subject: sdkRequest, next: TestHandler<TestOutput>())
        
        switch result {
        case .success(let output):
            XCTAssert(output.value == 200)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
//    func testMiddlewareStackConvenienceFunction() {
//        let context = TestContext()
//        var stack = OperationStack<TestOutput>(id: "Test Operation")
//        stack.initializeStep.intercept(position: .before, id: "add a header") { (context, input) -> Result<SdkHttpRequest, Error> in
//
//            input.headers.add(name: "Test", value: "Value")
//
//            return .success(input)
//        }
//        var input = TestInput()
//        let sdkRequest = try! input.buildHttpRequest(method: .get, path: "/", encoder: JSONEncoder())
//
//        let result = stack.handleMiddleware(context: context, subject: sdkRequest, next: TestHandler<TestOutput>())
//
//        switch result {
//        case .success(let output):
//            XCTAssert(output.value == 200)
//        case .failure(let error):
//            XCTFail(error.localizedDescription)
//        }
//    }
}
 
 struct TestHandler<Output: HttpResponseBinding>: Handler {
    
    func handle(context: MiddlewareContext, input: SdkHttpRequest) -> Result<Output, Error> {
        let httpResponse = HttpResponse(body: HttpBody.none, statusCode: HttpStatusCode.ok)
        let decoder = JSONDecoder()
        let output = try! Output(httpResponse: httpResponse, decoder: decoder)
        return .success(output)
    }
    
    typealias Input = SdkHttpRequest
    
    typealias Output = Output
    
    
 }
 
 struct TestMiddleware: Middleware {
    
    var id: String
    
    func handle<H>(context: MiddlewareContext, input: SdkHttpRequest, next: H) -> Result<TestOutput, Error> where H : Handler, Self.MInput == H.Input, Self.MOutput == H.Output {
        input.headers.add(name: "Test", value: "Value")
        
        return next.handle(context: context, input: input)
    }
    
    typealias MInput = SdkHttpRequest
    
    typealias MOutput = TestOutput
    
    
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
