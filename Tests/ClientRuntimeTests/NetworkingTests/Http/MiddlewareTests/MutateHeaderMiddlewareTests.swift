//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI
import XCTest
@testable import ClientRuntime
import SmithyTestUtil

class MutateHeaderMiddlewareTests: XCTestCase {
    var httpClientConfiguration: HttpClientConfiguration! = nil
    var clientEngine: MockHttpClientEngine! = nil
    var httpClient: SdkHttpClient! = nil
    var builtContext: Context! = nil
    var builder: OrchestratorBuilder<MockInput, MockOutput, SdkHttpRequest, HttpResponse>! = nil

    override func setUp() {
        httpClientConfiguration = HttpClientConfiguration()
        clientEngine = MockHttpClientEngine()
        httpClient = SdkHttpClient(engine: clientEngine, config: httpClientConfiguration)
        builtContext = ContextBuilder()
            .withMethod(value: .get)
            .withPath(value: "/headers")
            .withOperation(value: "Test Operation")
            .build()
        builder = TestOrchestrator.httpBuilder()
            .attributes(builtContext)
            .serialize(MockSerializeMiddleware(id: "TestMiddleware", headerName: "TestName", headerValue: "TestValue"))
            .deserialize(MockDeserializeMiddleware<MockOutput>(id: "TestDeserializeMiddleware", responseClosure: MockOutput.responseClosure(_:)))
            .executeRequest(httpClient)
    }

    func testOverridesHeaders() async throws {
        builder.interceptors.addModifyBeforeSigning({ ctx in
            ctx.updateRequest(updated: ctx.getRequest().toBuilder()
                .withHeader(name: "foo", value: "bar")
                .withHeader(name: "baz", value: "qux")
                .build()
            )
        })
        builder.interceptors.add(MutateHeadersMiddleware<MockInput, MockOutput>(overrides: ["foo": "override"], additional: ["z": "zebra"]))
        let output = try await builder.build().execute(input: MockInput())

        XCTAssertEqual(output.headers.value(for: "foo"), "override")
        XCTAssertEqual(output.headers.value(for: "z"), "zebra")
        XCTAssertEqual(output.headers.value(for: "baz"), "qux")
    }

    func testAppendsHeaders() async throws {
        builder.interceptors.addModifyBeforeSigning({ ctx in
            ctx.updateRequest(updated: ctx.getRequest().toBuilder()
                .withHeader(name: "foo", value: "bar")
                .withHeader(name: "baz", value: "qux")
                .build()
            )
        })
        builder.interceptors.add(MutateHeadersMiddleware<MockInput, MockOutput>(additional: ["foo": "appended", "z": "zebra"]))
        let output = try await builder.build().execute(input: MockInput())

        XCTAssertEqual(output.headers.values(for: "foo")?.sorted(), ["appended", "bar"].sorted())
        XCTAssertEqual(output.headers.value(for: "z"), "zebra")
        XCTAssertEqual(output.headers.value(for: "baz"), "qux")
    }

    func testConditionallySetHeaders() async throws {
        builder.interceptors.addModifyBeforeSigning({ ctx in
            ctx.updateRequest(updated: ctx.getRequest().toBuilder()
                .withHeader(name: "foo", value: "bar")
                .withHeader(name: "baz", value: "qux")
                .build()
            )
        })
        builder.interceptors.add(MutateHeadersMiddleware<MockInput, MockOutput>(conditionallySet: ["foo": "nope", "z": "zebra"]))
        let output = try await builder.build().execute(input: MockInput())

        XCTAssertEqual(output.headers.value(for: "foo"), "bar")
        XCTAssertEqual(output.headers.value(for: "z"), "zebra")
        XCTAssertEqual(output.headers.value(for: "baz"), "qux")
    }
}
