//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI
import XCTest
import ClientRuntime
import SmithyTestUtil

class ProviderTests: HttpRequestTestBase {

    func testURlPathProvider() {
        var mockInput = MockInput()
        mockInput.value = 3

        XCTAssert(MockInput.urlPathProvider(mockInput) == "/3")
    }

    func testURLPathMiddleware() async throws {
        var mockInput = MockInput()
        mockInput.value = 3

        let context = ContextBuilder().build()

        var operationStack = OperationStack<MockInput, MockOutput>(id: "testURLPathOperation")
        operationStack.initializeStep.intercept(position: .after, middleware: URLPathMiddleware<MockInput, MockOutput>(MockInput.urlPathProvider(_:)))
        operationStack.deserializeStep.intercept(position: .after, middleware: MockDeserializeMiddleware<MockOutput>(id: "TestDeserializeMiddleware", responseClosure: MockOutput.responseClosure(_:)))
        _ = try await operationStack.handleMiddleware(context: context,
                                        input: mockInput,
                                        next: MockHandler { (context, request) in

            XCTAssert(context.getPath() == "/3")
            let httpResponse = HttpResponse(body: ByteStream.noStream, statusCode: HttpStatusCode.ok)
            let output = OperationOutput<MockOutput>(httpResponse: httpResponse)
            return output
        })
    }

    func testQueryItemMiddleware() async throws {
        var mockInput = MockInput()
        mockInput.value = 3

        let context = ContextBuilder().build()

        var operationStack = OperationStack<MockInput, MockOutput>(id: "testURLPathOperation")
        operationStack.serializeStep.intercept(position: .after, middleware: QueryItemMiddleware(MockInput.queryItemProvider(_:)))
        operationStack.deserializeStep.intercept(position: .after, middleware: MockDeserializeMiddleware<MockOutput>(id: "TestDeserializeMiddleware", responseClosure: MockOutput.responseClosure(_:)))
        _ = try await operationStack.handleMiddleware(context: context,
                                        input: mockInput,
                                        next: MockHandler { (context, request) in

            XCTAssert(request.queryItems?.count == 1)
            XCTAssert(request.queryItems?.first(where: { queryItem in
                queryItem.value == "3"
            }) != nil)
            let httpResponse = HttpResponse(body: ByteStream.noStream, statusCode: HttpStatusCode.ok)
            let output = OperationOutput<MockOutput>(httpResponse: httpResponse)
            return output
        })
    }

    func testHeaderProvider() {
        var mockInput = MockInput()
        mockInput.value = 3

        XCTAssert(MockInput.headerProvider(mockInput).headers.count == 1)
    }

    func testHeaderMiddleware() async throws {
        var mockInput = MockInput()
        mockInput.value = 3

        let context = ContextBuilder().build()

        var operationStack = OperationStack<MockInput, MockOutput>(id: "testURLPathOperation")
        operationStack.serializeStep.intercept(position: .after, middleware: HeaderMiddleware(MockInput.headerProvider(_:)))
        operationStack.deserializeStep.intercept(position: .after, middleware: MockDeserializeMiddleware<MockOutput>(id: "TestDeserializeMiddleware", responseClosure: MockOutput.responseClosure(_:)))
        _ = try await operationStack.handleMiddleware(context: context,
                                        input: mockInput,
                                        next: MockHandler { (context, request) in

            XCTAssert(request.headers.headers.count == 1)
            XCTAssert(request.headers.headers.first(where: { header in
                header.value == ["3"]
            }) != nil)
            let httpResponse = HttpResponse(body: ByteStream.noStream, statusCode: HttpStatusCode.ok)
            let output = OperationOutput<MockOutput>(httpResponse: httpResponse)
            return output
        })
    }
}

extension MockInput {

    static func urlPathProvider(_ mock: MockInput) -> String? {
        guard let value = mock.value else {
            return nil
        }
        return "/\(value)"
    }

    static func queryItemProvider(_ mock: MockInput) -> [SDKURLQueryItem] {
        var items = [SDKURLQueryItem]()

        if let value = mock.value {
            let valueQueryItem = SDKURLQueryItem(name: "test", value: "\(value)")
            items.append(valueQueryItem)
        }
        return items
    }

    static func headerProvider(_ mock: MockInput) -> Headers {
        var items = Headers()

        if let value = mock.value {
            let headerItem = Header(name: "test", value: "\(value)")
            items.add(headerItem)
        }

        return items
    }
}
