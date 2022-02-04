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
            let output = OperationOutput<MockOutput>(httpResponse: httpResponse)
            return .success(output)
        })
    }
    
    func testQueryItemProvider() {
        var mockInput = MockInput()
        mockInput.value = 3
        
        XCTAssert(mockInput.queryItems.count == 1)
    }
    
    func testQueryItemMiddleware() {
        var mockInput = MockInput()
        mockInput.value = 3
        
        let context = HttpContextBuilder().withDecoder(value: JSONDecoder()).build()
        
        var operationStack = OperationStack<MockInput, MockOutput, MockMiddlewareError>(id: "testURLPathOperation")
        operationStack.serializeStep.intercept(position: .after, middleware: QueryItemMiddleware())
        operationStack.deserializeStep.intercept(position: .after, middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(id: "TestDeserializeMiddleware"))
        _ = operationStack.handleMiddleware(context: context,
                                        input: mockInput,
                                        next: MockHandler { (context, request) in
            
            XCTAssert(request.queryItems?.count == 1)
            XCTAssert(request.queryItems?.first(where: { queryItem in
                queryItem.value == "3"
            }) != nil)
            let httpResponse = HttpResponse(body: HttpBody.none, statusCode: HttpStatusCode.ok)
            let output = OperationOutput<MockOutput>(httpResponse: httpResponse)
            return .success(output)
        })
    }
}

extension MockInput: URLPathProvider, QueryItemProvider {
    public var urlPath: String? {
        guard let value = value else {
            return nil
        }
        return "/\(value)"
    }
    
    public var queryItems: [ClientRuntime.URLQueryItem] {
        var items = [ClientRuntime.URLQueryItem]()
        
        if let value = value {
            let valueQueryItem = URLQueryItem(name: "test", value: "\(value)")
            items.append(valueQueryItem)
        }
        return items
    }
}
