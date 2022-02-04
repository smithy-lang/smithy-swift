//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
import XCTest
import ClientRuntime
import SmithyTestUtil

class ProviderTests: HttpRequestTestBase {
    
    func testURlPathProvider() {
        var mockInput = MockInput()
        mockInput.value = 3
        
        XCTAssert(mockInput.urlPath == "/3")
    }
    
    func testURLPathMiddleware() {
        var mockInput = MockInput()
        mockInput.value = 3
        
        let context = HttpContextBuilder().withDecoder(value: JSONDecoder()).build()
        
        var operationStack = OperationStack<MockInput, MockOutput, MockMiddlewareError>(id: "testURLPathOperation")
        operationStack.initializeStep.intercept(position: .after, middleware: URLPathMiddleware())
        operationStack.deserializeStep.intercept(position: .after, middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(id: "TestDeserializeMiddleware"))
        _ = operationStack.handleMiddleware(context: context,
                                        input: mockInput,
                                        next: MockHandler { (context, request) in
            
            XCTAssert(context.getPath() == "/3")
            let httpResponse = HttpResponse(body: HttpBody.none, statusCode: HttpStatusCode.ok)
            //let mockOutput = try MockOutput(httpResponse: httpResponse, decoder: nil)
            let output = OperationOutput<MockOutput>(httpResponse: httpResponse)
            return .success(output)
        })
    }
}

extension MockInput: URLPathProvider {
    public var urlPath: String? {
        guard let value = value else {
            return nil
        }
        return "/\(value)"
    }
    
    
}
