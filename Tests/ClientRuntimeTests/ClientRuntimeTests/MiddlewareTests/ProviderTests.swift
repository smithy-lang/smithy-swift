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

    func testURLPathMiddleware() async throws {
        var mockInput = MockInput()
        mockInput.value = 3

        let context = HttpContextBuilder().withDecoder(value: JSONDecoder()).build()

        var operationStack = OperationStack<MockInput, MockOutput>(id: "testURLPathOperation")
        operationStack.initializeStep.intercept(position: .after, middleware: URLPathMiddleware<MockInput, MockOutput>())
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

        let context = HttpContextBuilder().withDecoder(value: JSONDecoder()).build()

        var operationStack = OperationStack<MockInput, MockOutput>(id: "testURLPathOperation")
        operationStack.serializeStep.intercept(position: .after, middleware: QueryItemMiddleware())
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

        XCTAssert(mockInput.headers.headers.count == 1)
    }

    func testHeaderMiddleware() async throws {
        var mockInput = MockInput()
        mockInput.value = 3

        let context = HttpContextBuilder().withDecoder(value: JSONDecoder()).build()

        var operationStack = OperationStack<MockInput, MockOutput>(id: "testURLPathOperation")
        operationStack.serializeStep.intercept(position: .after, middleware: HeaderMiddleware())
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

extension MockInput: URLPathProvider, QueryItemProvider, HeaderProvider {
    public var urlPath: String? {
        guard let value = value else {
            return nil
        }
        return "/\(value)"
    }

    public var queryItems: [ClientRuntime.URLQueryItem] {
        var items = [ClientRuntime.URLQueryItem]()

        if let value = value {
            let valueQueryItem = ClientRuntime.URLQueryItem(name: "test", value: "\(value)")
            items.append(valueQueryItem)
        }
        return items
    }

    public var headers: Headers {
        var items = Headers()

        if let value = value {
            let headerItem = Header(name: "test", value: "\(value)")
            items.add(headerItem)
        }

        return items
    }
}
