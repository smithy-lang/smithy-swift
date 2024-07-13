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

    func orchestratorBuilder() -> OrchestratorBuilder<MockInput, MockOutput, SdkHttpRequest, HttpResponse> {
        return TestOrchestrator.httpBuilder()
            .serialize(MockSerializeMiddleware(id: "TestMiddleware", headerName: "TestName", headerValue: "TestValue"))
            .deserialize(MockDeserializeMiddleware<MockOutput>(id: "TestDeserializeMiddleware", responseClosure: MockOutput.responseClosure(_:)))
    }

    func testURLPathProvider() {
        var mockInput = MockInput()
        mockInput.value = 3

        XCTAssert(MockInput.urlPathProvider(mockInput) == "/3")
    }

    func testURLPathMiddleware() async throws {
        var mockInput = MockInput()
        mockInput.value = 3

        let context = ContextBuilder().build()

        let builder = orchestratorBuilder()
        builder.attributes(context)
        builder.interceptors.add(URLPathMiddleware<MockInput, MockOutput>(MockInput.urlPathProvider(_:)))
        builder.deserialize(MockDeserializeMiddleware<MockOutput>(id: "TestDeserializeMiddleware", responseClosure: MockOutput.responseClosure(_:)))
        builder.executeRequest({ _, context in
            XCTAssertEqual(context.path, "/3")
            return HttpResponse(body: ByteStream.noStream, statusCode: HttpStatusCode.ok)
        })
        _ = try await builder.build().execute(input: mockInput)
    }

    func testQueryItemMiddleware() async throws {
        var mockInput = MockInput()
        mockInput.value = 3

        let context = ContextBuilder().withPath(value: "/").build()

        let builder = orchestratorBuilder()
        builder.attributes(context)
        builder.serialize(QueryItemMiddleware<MockInput, MockOutput>(MockInput.queryItemProvider(_:)))
        builder.deserialize(MockDeserializeMiddleware<MockOutput>(id: "TestDeserializeMiddleware", responseClosure: MockOutput.responseClosure(_:)))
        builder.executeRequest({ request, context in
            XCTAssert(request.queryItems?.count == 1)
            XCTAssert(request.queryItems?.first(where: { queryItem in
                queryItem.value == "3"
            }) != nil)
            return HttpResponse(body: ByteStream.noStream, statusCode: HttpStatusCode.ok)
        })
        _ = try await builder.build().execute(input: mockInput)
    }

    func testHeaderProvider() {
        var mockInput = MockInput()
        mockInput.value = 3

        XCTAssert(MockInput.headerProvider(mockInput).headers.count == 1)
    }

    func testHeaderMiddleware() async throws {
        var mockInput = MockInput()
        mockInput.value = 3

        let context = ContextBuilder().withPath(value: "/").build()

        let builder = orchestratorBuilder()
        builder.attributes(context)
        builder.serialize(HeaderMiddleware<MockInput, MockOutput>(MockInput.headerProvider(_:)))
        builder.deserialize(MockDeserializeMiddleware<MockOutput>(id: "TestDeserializeMiddleware", responseClosure: MockOutput.responseClosure(_:)))
        builder.executeRequest({ (request, context) in
            XCTAssert(request.headers.headers.first(where: { header in
                header.value == ["3"]
            }) != nil)
            return HttpResponse(body: ByteStream.noStream, statusCode: HttpStatusCode.ok)
        })
        _ = try await builder.build().execute(input: mockInput)
    }
}

extension MockInput {

    static func urlPathProvider(_ mock: MockInput) -> String? {
        guard let value = mock.value else {
            return nil
        }
        return "/\(value)"
    }

    static func queryItemProvider(_ mock: MockInput) -> [URIQueryItem] {
        var items = [URIQueryItem]()

        if let value = mock.value {
            let valueQueryItem = URIQueryItem(name: "test", value: "\(value)")
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
