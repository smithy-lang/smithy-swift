/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.model.AddOperationShapes

class HttpProtocolUnitTestRequestGeneratorTests {
    var model = javaClass.getResource("http-binding-protocol-generator-test.smithy").asSmithy()
    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        return model.newTestContext()
    }

    val ctx = newTestContext()
    init {
        ctx.generator.initializeMiddleware(ctx.generationCtx)
        ctx.generator.generateProtocolUnitTests(ctx.generationCtx)
        ctx.generationCtx.delegator.flushWriters()
    }

    @Test
    fun `it creates smoke test request test`() {
        val contents = getTestFileContents("example", "SmokeTestRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()

        val expectedContents = """
    func testSmokeTest() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .post,
            path: "/smoketest/{label1}/foo",
            headers: [
                "X-Header1": "Foo",
                "X-Header2": "Bar"
            ],
            requiredHeaders: [
                "Content-Length"
            ],
            queryParams: [
                "Query1=Query 1"
            ],
            body: .data(Data(""${'"'}
            {
            "payload1": "String",
            "payload2": 2,
            "payload3": {
                "member1": "test string",
                "member2": "test string 2"
                }
            }
            ""${'"'}.utf8)),
            host: "",
            resolvedHost: ""
        )

        let input = SmokeTestInput(
            header1: "Foo",
            header2: "Bar",
            label1: "label",
            payload1: "String",
            payload2: 2,
            payload3: Nested(
                member1: "test string",
                member2: "test string 2"
            ),
            query1: "Query 1"
        )
        let context = HttpContextBuilder()
                      .withMethod(value: .post)
                      .build()
        var operationStack = OperationStack<SmokeTestInput, SmokeTestOutput>(id: "SmokeTest")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<SmokeTestInput, SmokeTestOutput>(urlPrefix: urlPrefix, SmokeTestInput.urlPathProvider(_:)))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<SmokeTestInput, SmokeTestOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<SmokeTestOutput> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.HeaderMiddleware<SmokeTestInput, SmokeTestOutput>(SmokeTestInput.headerProvider(_:)))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.QueryItemMiddleware<SmokeTestInput, SmokeTestOutput>(SmokeTestInput.queryItemProvider(_:)))
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<SmokeTestInput, SmokeTestOutput>(contentType: "application/json"))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.BodyMiddleware<SmokeTestInput, SmokeTestOutput, SmithyJSON.Writer>(rootNodeInfo: "", inputWritingClosure: SmokeTestInput.write(value:to:)))
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware<SmokeTestInput, SmokeTestOutput>())
        operationStack.deserializeStep.intercept(
            position: .after,
            middleware: MockDeserializeMiddleware<SmokeTestOutput>(
                id: "TestDeserializeMiddleware",
                responseClosure: SmokeTestOutput.httpOutput(from:),
                callback: { context, actual in
                    try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                        XCTAssertNotNil(actualHttpBody, "The actual ByteStream is nil")
                        XCTAssertNotNil(expectedHttpBody, "The expected ByteStream is nil")
                        try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, contentType: .json)
                    })
                    return OperationOutput(httpResponse: HttpResponse(body: ByteStream.noStream, statusCode: .ok), output: SmokeTestOutput())
                }
            )
        )
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler() { (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            throw SmithyTestUtilError("Mock handler unexpectedly failed")
        })
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates explicit string test`() {
        val contents = getTestFileContents("example", "ExplicitStringRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testExplicitString() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .post,
            path: "/explicit/string",
            requiredHeaders: [
                "Content-Length"
            ],
            body: .data(Data(""${'"'}
            {
            "payload1": "explicit string"
            }
            ""${'"'}.utf8)),
            host: "",
            resolvedHost: ""
        )

        let input = ExplicitStringInput(
            payload1: "explicit string"
        )
        let context = HttpContextBuilder()
                      .withMethod(value: .post)
                      .build()
        var operationStack = OperationStack<ExplicitStringInput, ExplicitStringOutput>(id: "ExplicitString")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<ExplicitStringInput, ExplicitStringOutput>(urlPrefix: urlPrefix, ExplicitStringInput.urlPathProvider(_:)))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<ExplicitStringInput, ExplicitStringOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<ExplicitStringOutput> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<ExplicitStringInput, ExplicitStringOutput>(contentType: "text/plain"))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.StringBodyMiddleware<ExplicitStringInput, ExplicitStringOutput>(keyPath: \.payload1))
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware<ExplicitStringInput, ExplicitStringOutput>())
        operationStack.deserializeStep.intercept(
            position: .after,
            middleware: MockDeserializeMiddleware<ExplicitStringOutput>(
                id: "TestDeserializeMiddleware",
                responseClosure: ExplicitStringOutput.httpOutput(from:),
                callback: { context, actual in
                    try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                        XCTAssertNotNil(actualHttpBody, "The actual ByteStream is nil")
                        XCTAssertNotNil(expectedHttpBody, "The expected ByteStream is nil")
                        try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, contentType: .json)
                    })
                    return OperationOutput(httpResponse: HttpResponse(body: ByteStream.noStream, statusCode: .ok), output: ExplicitStringOutput())
                }
            )
        )
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler() { (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            throw SmithyTestUtilError("Mock handler unexpectedly failed")
        })
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for a request without a body`() {
        val contents = getTestFileContents("example", "EmptyInputAndEmptyOutputRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testRestJsonEmptyInputAndEmptyOutput() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .post,
            path: "/EmptyInputAndEmptyOutput",
            body: nil,
            host: "",
            resolvedHost: ""
        )

        let input = EmptyInputAndEmptyOutputInput(
        )
        let context = HttpContextBuilder()
                      .withMethod(value: .post)
                      .build()
        var operationStack = OperationStack<EmptyInputAndEmptyOutputInput, EmptyInputAndEmptyOutputOutput>(id: "RestJsonEmptyInputAndEmptyOutput")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<EmptyInputAndEmptyOutputInput, EmptyInputAndEmptyOutputOutput>(urlPrefix: urlPrefix, EmptyInputAndEmptyOutputInput.urlPathProvider(_:)))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<EmptyInputAndEmptyOutputInput, EmptyInputAndEmptyOutputOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<EmptyInputAndEmptyOutputOutput> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.deserializeStep.intercept(
            position: .after,
            middleware: MockDeserializeMiddleware<EmptyInputAndEmptyOutputOutput>(
                id: "TestDeserializeMiddleware",
                responseClosure: EmptyInputAndEmptyOutputOutput.httpOutput(from:),
                callback: { context, actual in
                    try await self.assertEqual(expected, actual)
                    return OperationOutput(httpResponse: HttpResponse(body: ByteStream.noStream, statusCode: .ok), output: EmptyInputAndEmptyOutputOutput())
                }
            )
        )
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler() { (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            throw SmithyTestUtilError("Mock handler unexpectedly failed")
        })
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for a request without a body given an empty object`() {
        val contents = getTestFileContents("example", "SimpleScalarPropertiesRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testRestJsonDoesntSerializeNullStructureValues() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/SimpleScalarProperties",
            headers: [
                "Content-Type": "application/json"
            ],
            body: .data(Data(""${'"'}
            {}
            ""${'"'}.utf8)),
            host: "",
            resolvedHost: ""
        )

        let input = SimpleScalarPropertiesInput(
            stringValue: nil
        )
        let context = HttpContextBuilder()
                      .withMethod(value: .put)
                      .build()
        var operationStack = OperationStack<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutput>(id: "RestJsonDoesntSerializeNullStructureValues")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutput>(urlPrefix: urlPrefix, SimpleScalarPropertiesInput.urlPathProvider(_:)))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<SimpleScalarPropertiesOutput> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.HeaderMiddleware<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutput>(SimpleScalarPropertiesInput.headerProvider(_:)))
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutput>(contentType: "application/json"))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.BodyMiddleware<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutput, SmithyJSON.Writer>(rootNodeInfo: "", inputWritingClosure: SimpleScalarPropertiesInput.write(value:to:)))
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutput>())
        operationStack.deserializeStep.intercept(
            position: .after,
            middleware: MockDeserializeMiddleware<SimpleScalarPropertiesOutput>(
                id: "TestDeserializeMiddleware",
                responseClosure: SimpleScalarPropertiesOutput.httpOutput(from:),
                callback: { context, actual in
                    try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                        XCTAssertNotNil(actualHttpBody, "The actual ByteStream is nil")
                        XCTAssertNotNil(expectedHttpBody, "The expected ByteStream is nil")
                        try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, contentType: .json)
                    })
                    return OperationOutput(httpResponse: HttpResponse(body: ByteStream.noStream, statusCode: .ok), output: SimpleScalarPropertiesOutput())
                }
            )
        )
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler() { (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            throw SmithyTestUtilError("Mock handler unexpectedly failed")
        })
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test with a string to be converted to data`() {
        val contents = getTestFileContents("example", "StreamingTraitsRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testRestJsonStreamingTraitsWithBlob() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .post,
            path: "/StreamingTraits",
            headers: [
                "Content-Type": "application/octet-stream",
                "X-Foo": "Foo"
            ],
            body: .stream(BufferedStream(data: Data(""${'"'}
            blobby blob blob
            ""${'"'}.utf8), isClosed: true)),
            host: "",
            resolvedHost: ""
        )

        let input = StreamingTraitsInput(
            blob: .stream(BufferedStream(data: "blobby blob blob".data(using: .utf8)!, isClosed: true)),
            foo: "Foo"
        )
        let context = HttpContextBuilder()
                      .withMethod(value: .post)
                      .build()
        var operationStack = OperationStack<StreamingTraitsInput, StreamingTraitsOutput>(id: "RestJsonStreamingTraitsWithBlob")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<StreamingTraitsInput, StreamingTraitsOutput>(urlPrefix: urlPrefix, StreamingTraitsInput.urlPathProvider(_:)))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<StreamingTraitsInput, StreamingTraitsOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<StreamingTraitsOutput> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.HeaderMiddleware<StreamingTraitsInput, StreamingTraitsOutput>(StreamingTraitsInput.headerProvider(_:)))
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<StreamingTraitsInput, StreamingTraitsOutput>(contentType: "application/octet-stream"))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.BlobStreamBodyMiddleware<StreamingTraitsInput, StreamingTraitsOutput>(keyPath: \.blob))
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware<StreamingTraitsInput, StreamingTraitsOutput>())
        operationStack.deserializeStep.intercept(
            position: .after,
            middleware: MockDeserializeMiddleware<StreamingTraitsOutput>(
                id: "TestDeserializeMiddleware",
                responseClosure: StreamingTraitsOutput.httpOutput(from:),
                callback: { context, actual in
                    try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                        XCTAssertNotNil(actualHttpBody, "The actual ByteStream is nil")
                        XCTAssertNotNil(expectedHttpBody, "The expected ByteStream is nil")
                        try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, contentType: .json)
                    })
                    return OperationOutput(httpResponse: HttpResponse(body: ByteStream.noStream, statusCode: .ok), output: StreamingTraitsOutput())
                }
            )
        )
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler() { (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            throw SmithyTestUtilError("Mock handler unexpectedly failed")
        })
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates unit test with an empty map`() {
        val contents = getTestFileContents("example", "HttpPrefixHeadersRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testRestJsonHttpPrefixHeadersAreNotPresent() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .get,
            path: "/HttpPrefixHeaders",
            headers: [
                "X-Foo": "Foo"
            ],
            body: nil,
            host: "",
            resolvedHost: ""
        )

        let input = HttpPrefixHeadersInput(
            foo: "Foo",
            fooMap: [:]

        )
        let context = HttpContextBuilder()
                      .withMethod(value: .get)
                      .build()
        var operationStack = OperationStack<HttpPrefixHeadersInput, HttpPrefixHeadersOutput>(id: "RestJsonHttpPrefixHeadersAreNotPresent")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<HttpPrefixHeadersInput, HttpPrefixHeadersOutput>(urlPrefix: urlPrefix, HttpPrefixHeadersInput.urlPathProvider(_:)))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<HttpPrefixHeadersInput, HttpPrefixHeadersOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<HttpPrefixHeadersOutput> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.HeaderMiddleware<HttpPrefixHeadersInput, HttpPrefixHeadersOutput>(HttpPrefixHeadersInput.headerProvider(_:)))
        operationStack.deserializeStep.intercept(
            position: .after,
            middleware: MockDeserializeMiddleware<HttpPrefixHeadersOutput>(
                id: "TestDeserializeMiddleware",
                responseClosure: HttpPrefixHeadersOutput.httpOutput(from:),
                callback: { context, actual in
                    try await self.assertEqual(expected, actual)
                    return OperationOutput(httpResponse: HttpResponse(body: ByteStream.noStream, statusCode: .ok), output: HttpPrefixHeadersOutput())
                }
            )
        )
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler() { (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            throw SmithyTestUtilError("Mock handler unexpectedly failed")
        })
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for union shapes`() {
        val contents = getTestFileContents("example", "JsonUnionsRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testRestJsonSerializeStringUnionValue() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/JsonUnions",
            headers: [
                "Content-Type": "application/json"
            ],
            body: .data(Data(""${'"'}
            {
                "contents": {
                    "stringValue": "foo"
                }
            }
            ""${'"'}.utf8)),
            host: "",
            resolvedHost: ""
        )

        let input = JsonUnionsInput(
            contents: MyUnion.stringvalue("foo")

        )
        let context = HttpContextBuilder()
                      .withMethod(value: .put)
                      .build()
        var operationStack = OperationStack<JsonUnionsInput, JsonUnionsOutput>(id: "RestJsonSerializeStringUnionValue")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<JsonUnionsInput, JsonUnionsOutput>(urlPrefix: urlPrefix, JsonUnionsInput.urlPathProvider(_:)))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<JsonUnionsInput, JsonUnionsOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<JsonUnionsOutput> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<JsonUnionsInput, JsonUnionsOutput>(contentType: "application/json"))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.BodyMiddleware<JsonUnionsInput, JsonUnionsOutput, SmithyJSON.Writer>(rootNodeInfo: "", inputWritingClosure: JsonUnionsInput.write(value:to:)))
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware<JsonUnionsInput, JsonUnionsOutput>())
        operationStack.deserializeStep.intercept(
            position: .after,
            middleware: MockDeserializeMiddleware<JsonUnionsOutput>(
                id: "TestDeserializeMiddleware",
                responseClosure: JsonUnionsOutput.httpOutput(from:),
                callback: { context, actual in
                    try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                        XCTAssertNotNil(actualHttpBody, "The actual ByteStream is nil")
                        XCTAssertNotNil(expectedHttpBody, "The expected ByteStream is nil")
                        try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, contentType: .json)
                    })
                    return OperationOutput(httpResponse: HttpResponse(body: ByteStream.noStream, statusCode: .ok), output: JsonUnionsOutput())
                }
            )
        )
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler() { (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            throw SmithyTestUtilError("Mock handler unexpectedly failed")
        })
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for recursive shapes`() {
        val contents = getTestFileContents("example", "RecursiveShapesRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testRestJsonRecursiveShapes() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/RecursiveShapes",
            headers: [
                "Content-Type": "application/json"
            ],
            body: .data(Data(""${'"'}
            {
                "nested": {
                    "foo": "Foo1",
                    "nested": {
                        "bar": "Bar1",
                        "recursiveMember": {
                            "foo": "Foo2",
                            "nested": {
                                "bar": "Bar2"
                            }
                        }
                    }
                }
            }
            ""${'"'}.utf8)),
            host: "",
            resolvedHost: ""
        )

        let input = RecursiveShapesInput(
            nested: RecursiveShapesInputOutputNested1(
                foo: "Foo1",
                nested: RecursiveShapesInputOutputNested2(
                    bar: "Bar1",
                    recursiveMember: RecursiveShapesInputOutputNested1(
                        foo: "Foo2",
                        nested: RecursiveShapesInputOutputNested2(
                            bar: "Bar2"
                        )
                    )
                )
            )
        )
        let context = HttpContextBuilder()
                      .withMethod(value: .put)
                      .build()
        var operationStack = OperationStack<RecursiveShapesInput, RecursiveShapesOutput>(id: "RestJsonRecursiveShapes")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<RecursiveShapesInput, RecursiveShapesOutput>(urlPrefix: urlPrefix, RecursiveShapesInput.urlPathProvider(_:)))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<RecursiveShapesInput, RecursiveShapesOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<RecursiveShapesOutput> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<RecursiveShapesInput, RecursiveShapesOutput>(contentType: "application/json"))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.BodyMiddleware<RecursiveShapesInput, RecursiveShapesOutput, SmithyJSON.Writer>(rootNodeInfo: "", inputWritingClosure: RecursiveShapesInput.write(value:to:)))
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware<RecursiveShapesInput, RecursiveShapesOutput>())
        operationStack.deserializeStep.intercept(
            position: .after,
            middleware: MockDeserializeMiddleware<RecursiveShapesOutput>(
                id: "TestDeserializeMiddleware",
                responseClosure: RecursiveShapesOutput.httpOutput(from:),
                callback: { context, actual in
                    try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                        XCTAssertNotNil(actualHttpBody, "The actual ByteStream is nil")
                        XCTAssertNotNil(expectedHttpBody, "The expected ByteStream is nil")
                        try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, contentType: .json)
                    })
                    return OperationOutput(httpResponse: HttpResponse(body: ByteStream.noStream, statusCode: .ok), output: RecursiveShapesOutput())
                }
            )
        )
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler() { (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            throw SmithyTestUtilError("Mock handler unexpectedly failed")
        })
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for inline document`() {
        val contents = getTestFileContents("example", "InlineDocumentRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testInlineDocumentInput() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/InlineDocument",
            headers: [
                "Content-Type": "application/json"
            ],
            body: .data(Data(""${'"'}
            {
                "stringValue": "string",
                "documentValue": {
                    "foo": "bar"
                }
            }
            ""${'"'}.utf8)),
            host: "",
            resolvedHost: ""
        )

        let input = InlineDocumentInput(
            documentValue: try SmithyReadWrite.Document.make(from: Data(""${'"'}
                {
                    "foo": "bar"
                }
            ""${'"'}.utf8))
            ,
            stringValue: "string"
        )
        let context = HttpContextBuilder()
                      .withMethod(value: .put)
                      .build()
        var operationStack = OperationStack<InlineDocumentInput, InlineDocumentOutput>(id: "InlineDocumentInput")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<InlineDocumentInput, InlineDocumentOutput>(urlPrefix: urlPrefix, InlineDocumentInput.urlPathProvider(_:)))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<InlineDocumentInput, InlineDocumentOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<InlineDocumentOutput> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<InlineDocumentInput, InlineDocumentOutput>(contentType: "application/json"))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.BodyMiddleware<InlineDocumentInput, InlineDocumentOutput, SmithyJSON.Writer>(rootNodeInfo: "", inputWritingClosure: InlineDocumentInput.write(value:to:)))
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware<InlineDocumentInput, InlineDocumentOutput>())
        operationStack.deserializeStep.intercept(
            position: .after,
            middleware: MockDeserializeMiddleware<InlineDocumentOutput>(
                id: "TestDeserializeMiddleware",
                responseClosure: InlineDocumentOutput.httpOutput(from:),
                callback: { context, actual in
                    try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                        XCTAssertNotNil(actualHttpBody, "The actual ByteStream is nil")
                        XCTAssertNotNil(expectedHttpBody, "The expected ByteStream is nil")
                        try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, contentType: .json)
                    })
                    return OperationOutput(httpResponse: HttpResponse(body: ByteStream.noStream, statusCode: .ok), output: InlineDocumentOutput())
                }
            )
        )
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler() { (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            throw SmithyTestUtilError("Mock handler unexpectedly failed")
        })
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for inline document as payload`() {
        val contents = getTestFileContents("example", "InlineDocumentAsPayloadRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testInlineDocumentAsPayloadInput() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/InlineDocumentAsPayload",
            headers: [
                "Content-Type": "application/json"
            ],
            body: .data(Data(""${'"'}
            {
                "foo": "bar"
            }
            ""${'"'}.utf8)),
            host: "",
            resolvedHost: ""
        )

        let input = InlineDocumentAsPayloadInput(
            documentValue: try SmithyReadWrite.Document.make(from: Data(""${'"'}
                {
                    "foo": "bar"
                }
            ""${'"'}.utf8))

        )
        let context = HttpContextBuilder()
                      .withMethod(value: .put)
                      .build()
        var operationStack = OperationStack<InlineDocumentAsPayloadInput, InlineDocumentAsPayloadOutput>(id: "InlineDocumentAsPayloadInput")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<InlineDocumentAsPayloadInput, InlineDocumentAsPayloadOutput>(urlPrefix: urlPrefix, InlineDocumentAsPayloadInput.urlPathProvider(_:)))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<InlineDocumentAsPayloadInput, InlineDocumentAsPayloadOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<InlineDocumentAsPayloadOutput> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<InlineDocumentAsPayloadInput, InlineDocumentAsPayloadOutput>(contentType: "application/json"))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.PayloadBodyMiddleware<InlineDocumentAsPayloadInput, InlineDocumentAsPayloadOutput, SmithyReadWrite.Document, SmithyJSON.Writer>(rootNodeInfo: "", inputWritingClosure: SmithyReadWrite.Document.write(value:to:), keyPath: \.documentValue, defaultBody: "{}"))
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware<InlineDocumentAsPayloadInput, InlineDocumentAsPayloadOutput>())
        operationStack.deserializeStep.intercept(
            position: .after,
            middleware: MockDeserializeMiddleware<InlineDocumentAsPayloadOutput>(
                id: "TestDeserializeMiddleware",
                responseClosure: InlineDocumentAsPayloadOutput.httpOutput(from:),
                callback: { context, actual in
                    try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                        XCTAssertNotNil(actualHttpBody, "The actual ByteStream is nil")
                        XCTAssertNotNil(expectedHttpBody, "The expected ByteStream is nil")
                        try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, contentType: .json)
                    })
                    return OperationOutput(httpResponse: HttpResponse(body: ByteStream.noStream, statusCode: .ok), output: InlineDocumentAsPayloadOutput())
                }
            )
        )
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler() { (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            throw SmithyTestUtilError("Mock handler unexpectedly failed")
        })
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
