/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.AddOperationShapes

class HttpProtocolUnitTestRequestGeneratorTests {
    var model = javaClass.getResource("http-binding-protocol-generator-test.smithy").asSmithy()
    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        return model.newTestContext()
    }

    val ctx = newTestContext()
    init {
        ctx.generator.generateProtocolUnitTests(ctx.generationCtx)
        ctx.generationCtx.delegator.flushWriters()
    }

    @Test
    fun `it creates smoke test request test`() {
        val contents = getTestFileContents("example", "SmokeTestRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()

        val expectedContents =
            """
    func testSmokeTest() {
        let expected = buildExpectedHttpRequest(
            method: .post,
            path: "/smoketest/{label1}/foo",
            headers: [
                "X-Header1": "Foo",
                "X-Header2": "Bar"
            ],
            queryParams: [
                "Query1=Query 1"
            ],
            body: ""${'"'}
            {
            "payload1": "String",
            "payload2": 2,
            "payload3": {
                "member1": "test string",
                "member2": "test string 2"
                }
            }
            ""${'"'},
            host: host
        )

        let deserializeMiddleware = expectation(description: "deserializeMiddleware")

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
        let mockSerializeStackStep: MockSerializeStackStep<SmokeTestInput> = constructMockSerializeStackStep(interceptCallback: {
            var step = SerializeStep<SmokeTestInput>()
            step.intercept(position: .before, middleware: SmokeTestInputHeadersMiddleware())
            step.intercept(position: .before, middleware: SmokeTestInputQueryItemMiddleware())
            step.intercept(position: .before, middleware: SmokeTestInputBodyMiddleware())
            return step
        })
        let mockBuildStackStep: MockBuildStackStep<SmokeTestInput> = constructMockBuildStackStep(interceptCallback: {
            var step = BuildStep<SmokeTestInput>()
            step.intercept(position: .before, middleware: ContentLengthMiddleware<SmokeTestInput>())
            return step
        })
        let mockDeserializeStackStep: MockDeserializeStackStep<MockOutput, MockMiddlewareError> = constructMockDeserializeStackStep(interceptCallback: {
            var step = DeserializeStep<MockOutput, MockMiddlewareError>()
            step.intercept(position: .after,
                         middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(
                                 id: "TestDeserializeMiddleware"){ context, actual in
                let requiredHeaders = ["Content-Length"]
                // assert required headers do exist
                for requiredHeader in requiredHeaders {
                    XCTAssertTrue(
                        self.headerExists(requiredHeader, in: actual.headers.headers),
                        "Required Header:\(requiredHeader) does not exist in headers"
                    )
                }
                self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                    XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                    XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                    self.assertEqualHttpBodyData(expectedHttpBody!, actualHttpBody!)
                })
                let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
                let mockOutput = try! MockOutput(httpResponse: response, decoder: nil)
                let output = DeserializeOutput<MockOutput, MockMiddlewareError>(httpResponse: response, output: mockOutput)
                deserializeMiddleware.fulfill()
                return .success(output)
            })
            return step
        })
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        let operationStack = OperationStack<SmokeTestInput, MockOutput, MockMiddlewareError>(id: "SmokeTest",
        serializeStackStep: mockSerializeStackStep,
        buildStackStep: mockBuildStackStep,
        deserializeStackStep: mockDeserializeStackStep)
        _ = operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            return .failure(try! MockMiddlewareError(httpResponse: HttpResponse(body: .none, statusCode: .badRequest)))
        })
        wait(for: [deserializeMiddleware], timeout: 0.3)
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates explicit string test`() {
        val contents = getTestFileContents("example", "ExplicitStringRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testExplicitString() {
        let expected = buildExpectedHttpRequest(
            method: .post,
            path: "/explicit/string",
            headers: [String: String](),
            queryParams: [String](),
            body: ""${'"'}
            {
            "payload1": "explicit string"
            }
            ""${'"'},
            host: host
        )

        let deserializeMiddleware = expectation(description: "deserializeMiddleware")

        let input = ExplicitStringInput(
            payload1: "explicit string"
        )
        let mockSerializeStackStep: MockSerializeStackStep<ExplicitStringInput> = constructMockSerializeStackStep(interceptCallback: {
            var step = SerializeStep<ExplicitStringInput>()
            step.intercept(position: .before, middleware: ExplicitStringInputHeadersMiddleware())
            step.intercept(position: .before, middleware: ExplicitStringInputQueryItemMiddleware())
            step.intercept(position: .before, middleware: ExplicitStringInputBodyMiddleware())
            return step
        })
        let mockBuildStackStep: MockBuildStackStep<ExplicitStringInput> = constructMockBuildStackStep(interceptCallback: {
            var step = BuildStep<ExplicitStringInput>()
            step.intercept(position: .before, middleware: ContentLengthMiddleware<ExplicitStringInput>())
            return step
        })
        let mockDeserializeStackStep: MockDeserializeStackStep<MockOutput, MockMiddlewareError> = constructMockDeserializeStackStep(interceptCallback: {
            var step = DeserializeStep<MockOutput, MockMiddlewareError>()
            step.intercept(position: .after,
                         middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(
                                 id: "TestDeserializeMiddleware"){ context, actual in
                let requiredHeaders = ["Content-Length"]
                // assert required headers do exist
                for requiredHeader in requiredHeaders {
                    XCTAssertTrue(
                        self.headerExists(requiredHeader, in: actual.headers.headers),
                        "Required Header:\(requiredHeader) does not exist in headers"
                    )
                }
                self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                    XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                    XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                    self.assertEqualHttpBodyData(expectedHttpBody!, actualHttpBody!)
                })
                let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
                let mockOutput = try! MockOutput(httpResponse: response, decoder: nil)
                let output = DeserializeOutput<MockOutput, MockMiddlewareError>(httpResponse: response, output: mockOutput)
                deserializeMiddleware.fulfill()
                return .success(output)
            })
            return step
        })
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        let operationStack = OperationStack<ExplicitStringInput, MockOutput, MockMiddlewareError>(id: "ExplicitString",
        serializeStackStep: mockSerializeStackStep,
        buildStackStep: mockBuildStackStep,
        deserializeStackStep: mockDeserializeStackStep)
        _ = operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            return .failure(try! MockMiddlewareError(httpResponse: HttpResponse(body: .none, statusCode: .badRequest)))
        })
        wait(for: [deserializeMiddleware], timeout: 0.3)
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for a request without a body`() {
        val contents = getTestFileContents("example", "EmptyInputAndEmptyOutputRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testRestJsonEmptyInputAndEmptyOutput() {
        let expected = buildExpectedHttpRequest(
            method: .post,
            path: "/EmptyInputAndEmptyOutput",
            headers: [String: String](),
            queryParams: [String](),
            body: nil,
            host: host
        )

        let deserializeMiddleware = expectation(description: "deserializeMiddleware")

        let input = EmptyInputAndEmptyOutputInput(
        )
        let mockSerializeStackStep: MockSerializeStackStep<EmptyInputAndEmptyOutputInput> = constructMockSerializeStackStep(interceptCallback: {
            var step = SerializeStep<EmptyInputAndEmptyOutputInput>()
            step.intercept(position: .before, middleware: EmptyInputAndEmptyOutputInputHeadersMiddleware())
            step.intercept(position: .before, middleware: EmptyInputAndEmptyOutputInputQueryItemMiddleware())
            return step
        })
        let mockDeserializeStackStep: MockDeserializeStackStep<MockOutput, MockMiddlewareError> = constructMockDeserializeStackStep(interceptCallback: {
            var step = DeserializeStep<MockOutput, MockMiddlewareError>()
            step.intercept(position: .after,
                         middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(
                                 id: "TestDeserializeMiddleware"){ context, actual in
                self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                    XCTAssert(actualHttpBody == HttpBody.none, "The actual HttpBody is not none as expected")
                    XCTAssert(expectedHttpBody == HttpBody.none, "The expected HttpBody is not none as expected")
                })
                let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
                let mockOutput = try! MockOutput(httpResponse: response, decoder: nil)
                let output = DeserializeOutput<MockOutput, MockMiddlewareError>(httpResponse: response, output: mockOutput)
                deserializeMiddleware.fulfill()
                return .success(output)
            })
            return step
        })
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        let operationStack = OperationStack<EmptyInputAndEmptyOutputInput, MockOutput, MockMiddlewareError>(id: "RestJsonEmptyInputAndEmptyOutput",
        serializeStackStep: mockSerializeStackStep,
        deserializeStackStep: mockDeserializeStackStep)
        _ = operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            return .failure(try! MockMiddlewareError(httpResponse: HttpResponse(body: .none, statusCode: .badRequest)))
        })
        wait(for: [deserializeMiddleware], timeout: 0.3)
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for a request without a body given an empty object`() {
        val contents = getTestFileContents("example", "SimpleScalarPropertiesRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testRestJsonDoesntSerializeNullStructureValues() {
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/SimpleScalarProperties",
            headers: [
                "Content-Type": "application/json"
            ],
            queryParams: [String](),
            body: nil,
            host: host
        )

        let deserializeMiddleware = expectation(description: "deserializeMiddleware")

        let input = SimpleScalarPropertiesInput(
            stringValue: nil
        )
        let mockSerializeStackStep: MockSerializeStackStep<SimpleScalarPropertiesInput> = constructMockSerializeStackStep(interceptCallback: {
            var step = SerializeStep<SimpleScalarPropertiesInput>()
            step.intercept(position: .before, middleware: SimpleScalarPropertiesInputHeadersMiddleware())
            step.intercept(position: .before, middleware: SimpleScalarPropertiesInputQueryItemMiddleware())
            step.intercept(position: .before, middleware: SimpleScalarPropertiesInputBodyMiddleware())
            step.intercept(position: .before, middleware: ContentTypeMiddleware<SimpleScalarPropertiesInput>(contentType: "application/json"))
            return step
        })
        let mockBuildStackStep: MockBuildStackStep<SimpleScalarPropertiesInput> = constructMockBuildStackStep(interceptCallback: {
            var step = BuildStep<SimpleScalarPropertiesInput>()
            step.intercept(position: .before, middleware: ContentLengthMiddleware<SimpleScalarPropertiesInput>())
            return step
        })
        let mockDeserializeStackStep: MockDeserializeStackStep<MockOutput, MockMiddlewareError> = constructMockDeserializeStackStep(interceptCallback: {
            var step = DeserializeStep<MockOutput, MockMiddlewareError>()
            step.intercept(position: .after,
                         middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(
                                 id: "TestDeserializeMiddleware"){ context, actual in
                self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                    XCTAssert(actualHttpBody == HttpBody.none, "The actual HttpBody is not none as expected")
                    XCTAssert(expectedHttpBody == HttpBody.none, "The expected HttpBody is not none as expected")
                })
                let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
                let mockOutput = try! MockOutput(httpResponse: response, decoder: nil)
                let output = DeserializeOutput<MockOutput, MockMiddlewareError>(httpResponse: response, output: mockOutput)
                deserializeMiddleware.fulfill()
                return .success(output)
            })
            return step
        })
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        let operationStack = OperationStack<SimpleScalarPropertiesInput, MockOutput, MockMiddlewareError>(id: "RestJsonDoesntSerializeNullStructureValues",
        serializeStackStep: mockSerializeStackStep,
        buildStackStep: mockBuildStackStep,
        deserializeStackStep: mockDeserializeStackStep)
        _ = operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            return .failure(try! MockMiddlewareError(httpResponse: HttpResponse(body: .none, statusCode: .badRequest)))
        })
        wait(for: [deserializeMiddleware], timeout: 0.3)
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test with a string to be converted to data`() {
        val contents = getTestFileContents("example", "StreamingTraitsRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testRestJsonStreamingTraitsWithBlob() {
        let expected = buildExpectedHttpRequest(
            method: .post,
            path: "/StreamingTraits",
            headers: [
                "Content-Type": "application/octet-stream",
                "X-Foo": "Foo"
            ],
            queryParams: [String](),
            body: ""${'"'}
            blobby blob blob
            ""${'"'},
            host: host
        )

        let deserializeMiddleware = expectation(description: "deserializeMiddleware")

        let input = StreamingTraitsInput(
            blob: "blobby blob blob".data(using: .utf8)!,
            foo: "Foo"
        )
        let mockSerializeStackStep: MockSerializeStackStep<StreamingTraitsInput> = constructMockSerializeStackStep(interceptCallback: {
            var step = SerializeStep<StreamingTraitsInput>()
            step.intercept(position: .before, middleware: StreamingTraitsInputHeadersMiddleware())
            step.intercept(position: .before, middleware: StreamingTraitsInputQueryItemMiddleware())
            step.intercept(position: .before, middleware: StreamingTraitsInputBodyMiddleware())
            step.intercept(position: .before, middleware: ContentTypeMiddleware<StreamingTraitsInput>(contentType: "application/octet-stream"))
            return step
        })
        let mockBuildStackStep: MockBuildStackStep<StreamingTraitsInput> = constructMockBuildStackStep(interceptCallback: {
            var step = BuildStep<StreamingTraitsInput>()
            step.intercept(position: .before, middleware: ContentLengthMiddleware<StreamingTraitsInput>())
            return step
        })
        let mockDeserializeStackStep: MockDeserializeStackStep<MockOutput, MockMiddlewareError> = constructMockDeserializeStackStep(interceptCallback: {
            var step = DeserializeStep<MockOutput, MockMiddlewareError>()
            step.intercept(position: .after,
                         middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(
                                 id: "TestDeserializeMiddleware"){ context, actual in
                self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                    XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                    XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                    self.assertEqualHttpBodyData(expectedHttpBody!, actualHttpBody!)
                })
                let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
                let mockOutput = try! MockOutput(httpResponse: response, decoder: nil)
                let output = DeserializeOutput<MockOutput, MockMiddlewareError>(httpResponse: response, output: mockOutput)
                deserializeMiddleware.fulfill()
                return .success(output)
            })
            return step
        })
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        let operationStack = OperationStack<StreamingTraitsInput, MockOutput, MockMiddlewareError>(id: "RestJsonStreamingTraitsWithBlob",
        serializeStackStep: mockSerializeStackStep,
        buildStackStep: mockBuildStackStep,
        deserializeStackStep: mockDeserializeStackStep)
        _ = operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            return .failure(try! MockMiddlewareError(httpResponse: HttpResponse(body: .none, statusCode: .badRequest)))
        })
        wait(for: [deserializeMiddleware], timeout: 0.3)
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates unit test with an empty map`() {
        val contents = getTestFileContents("example", "HttpPrefixHeadersRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testRestJsonHttpPrefixHeadersAreNotPresent() {
        let expected = buildExpectedHttpRequest(
            method: .get,
            path: "/HttpPrefixHeaders",
            headers: [
                "X-Foo": "Foo"
            ],
            queryParams: [String](),
            body: nil,
            host: host
        )

        let deserializeMiddleware = expectation(description: "deserializeMiddleware")

        let input = HttpPrefixHeadersInput(
            foo: "Foo",
            fooMap: [:]

        )
        let mockSerializeStackStep: MockSerializeStackStep<HttpPrefixHeadersInput> = constructMockSerializeStackStep(interceptCallback: {
            var step = SerializeStep<HttpPrefixHeadersInput>()
            step.intercept(position: .before, middleware: HttpPrefixHeadersInputHeadersMiddleware())
            step.intercept(position: .before, middleware: HttpPrefixHeadersInputQueryItemMiddleware())
            return step
        })
        let mockDeserializeStackStep: MockDeserializeStackStep<MockOutput, MockMiddlewareError> = constructMockDeserializeStackStep(interceptCallback: {
            var step = DeserializeStep<MockOutput, MockMiddlewareError>()
            step.intercept(position: .after,
                         middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(
                                 id: "TestDeserializeMiddleware"){ context, actual in
                self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                    XCTAssert(actualHttpBody == HttpBody.none, "The actual HttpBody is not none as expected")
                    XCTAssert(expectedHttpBody == HttpBody.none, "The expected HttpBody is not none as expected")
                })
                let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
                let mockOutput = try! MockOutput(httpResponse: response, decoder: nil)
                let output = DeserializeOutput<MockOutput, MockMiddlewareError>(httpResponse: response, output: mockOutput)
                deserializeMiddleware.fulfill()
                return .success(output)
            })
            return step
        })
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        let operationStack = OperationStack<HttpPrefixHeadersInput, MockOutput, MockMiddlewareError>(id: "RestJsonHttpPrefixHeadersAreNotPresent",
        serializeStackStep: mockSerializeStackStep,
        deserializeStackStep: mockDeserializeStackStep)
        _ = operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            return .failure(try! MockMiddlewareError(httpResponse: HttpResponse(body: .none, statusCode: .badRequest)))
        })
        wait(for: [deserializeMiddleware], timeout: 0.3)
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for union shapes`() {
        val contents = getTestFileContents("example", "JsonUnionsRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testRestJsonSerializeStringUnionValue() {
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/JsonUnions",
            headers: [
                "Content-Type": "application/json"
            ],
            queryParams: [String](),
            body: ""${'"'}
            {
                "contents": {
                    "stringValue": "foo"
                }
            }
            ""${'"'},
            host: host
        )

        let deserializeMiddleware = expectation(description: "deserializeMiddleware")

        let input = JsonUnionsInput(
            contents: MyUnion.stringValue("foo")

        )
        let mockSerializeStackStep: MockSerializeStackStep<JsonUnionsInput> = constructMockSerializeStackStep(interceptCallback: {
            var step = SerializeStep<JsonUnionsInput>()
            step.intercept(position: .before, middleware: JsonUnionsInputHeadersMiddleware())
            step.intercept(position: .before, middleware: JsonUnionsInputQueryItemMiddleware())
            step.intercept(position: .before, middleware: JsonUnionsInputBodyMiddleware())
            step.intercept(position: .before, middleware: ContentTypeMiddleware<JsonUnionsInput>(contentType: "application/json"))
            return step
        })
        let mockBuildStackStep: MockBuildStackStep<JsonUnionsInput> = constructMockBuildStackStep(interceptCallback: {
            var step = BuildStep<JsonUnionsInput>()
            step.intercept(position: .before, middleware: ContentLengthMiddleware<JsonUnionsInput>())
            return step
        })
        let mockDeserializeStackStep: MockDeserializeStackStep<MockOutput, MockMiddlewareError> = constructMockDeserializeStackStep(interceptCallback: {
            var step = DeserializeStep<MockOutput, MockMiddlewareError>()
            step.intercept(position: .after,
                         middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(
                                 id: "TestDeserializeMiddleware"){ context, actual in
                self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                    XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                    XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                    self.assertEqualHttpBodyJSONData(expectedHttpBody!, actualHttpBody!)
                })
                let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
                let mockOutput = try! MockOutput(httpResponse: response, decoder: nil)
                let output = DeserializeOutput<MockOutput, MockMiddlewareError>(httpResponse: response, output: mockOutput)
                deserializeMiddleware.fulfill()
                return .success(output)
            })
            return step
        })
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        let operationStack = OperationStack<JsonUnionsInput, MockOutput, MockMiddlewareError>(id: "RestJsonSerializeStringUnionValue",
        serializeStackStep: mockSerializeStackStep,
        buildStackStep: mockBuildStackStep,
        deserializeStackStep: mockDeserializeStackStep)
        _ = operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            return .failure(try! MockMiddlewareError(httpResponse: HttpResponse(body: .none, statusCode: .badRequest)))
        })
        wait(for: [deserializeMiddleware], timeout: 0.3)
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for recursive shapes`() {
        val contents = getTestFileContents("example", "RecursiveShapesRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testRestJsonRecursiveShapes() {
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/RecursiveShapes",
            headers: [
                "Content-Type": "application/json"
            ],
            queryParams: [String](),
            body: ""${'"'}
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
            ""${'"'},
            host: host
        )

        let deserializeMiddleware = expectation(description: "deserializeMiddleware")

        let input = RecursiveShapesInput(
            nested: RecursiveShapesInputOutputNested1(
                foo: "Foo1",
                nested: Box<RecursiveShapesInputOutputNested2>(
                    value: RecursiveShapesInputOutputNested2(
                        bar: "Bar1",
                        recursiveMember: RecursiveShapesInputOutputNested1(
                            foo: "Foo2",
                            nested: Box<RecursiveShapesInputOutputNested2>(
                                value: RecursiveShapesInputOutputNested2(
                                    bar: "Bar2"
                                )
                            )
                        )
                    )
                )
            )
        )
        let mockSerializeStackStep: MockSerializeStackStep<RecursiveShapesInput> = constructMockSerializeStackStep(interceptCallback: {
            var step = SerializeStep<RecursiveShapesInput>()
            step.intercept(position: .before, middleware: RecursiveShapesInputHeadersMiddleware())
            step.intercept(position: .before, middleware: RecursiveShapesInputQueryItemMiddleware())
            step.intercept(position: .before, middleware: RecursiveShapesInputBodyMiddleware())
            step.intercept(position: .before, middleware: ContentTypeMiddleware<RecursiveShapesInput>(contentType: "application/json"))
            return step
        })
        let mockBuildStackStep: MockBuildStackStep<RecursiveShapesInput> = constructMockBuildStackStep(interceptCallback: {
            var step = BuildStep<RecursiveShapesInput>()
            step.intercept(position: .before, middleware: ContentLengthMiddleware<RecursiveShapesInput>())
            return step
        })
        let mockDeserializeStackStep: MockDeserializeStackStep<MockOutput, MockMiddlewareError> = constructMockDeserializeStackStep(interceptCallback: {
            var step = DeserializeStep<MockOutput, MockMiddlewareError>()
            step.intercept(position: .after,
                         middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(
                                 id: "TestDeserializeMiddleware"){ context, actual in
                self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                    XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                    XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                    self.assertEqualHttpBodyJSONData(expectedHttpBody!, actualHttpBody!)
                })
                let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
                let mockOutput = try! MockOutput(httpResponse: response, decoder: nil)
                let output = DeserializeOutput<MockOutput, MockMiddlewareError>(httpResponse: response, output: mockOutput)
                deserializeMiddleware.fulfill()
                return .success(output)
            })
            return step
        })
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        let operationStack = OperationStack<RecursiveShapesInput, MockOutput, MockMiddlewareError>(id: "RestJsonRecursiveShapes",
        serializeStackStep: mockSerializeStackStep,
        buildStackStep: mockBuildStackStep,
        deserializeStackStep: mockDeserializeStackStep)
        _ = operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            return .failure(try! MockMiddlewareError(httpResponse: HttpResponse(body: .none, statusCode: .badRequest)))
        })
        wait(for: [deserializeMiddleware], timeout: 0.3)
 """
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for inline document`() {
        val contents = getTestFileContents("example", "InlineDocumentRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testInlineDocumentInput() {
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/InlineDocument",
            headers: [
                "Content-Type": "application/json"
            ],
            queryParams: [String](),
            body: ""${'"'}
            {
                "stringValue": "string",
                "documentValue": {
                    "foo": "bar"
                }
            }
            ""${'"'},
            host: host
        )

        let deserializeMiddleware = expectation(description: "deserializeMiddleware")

        let input = InlineDocumentInput(
            documentValue: Document(
                dictionaryLiteral:
                (
                    "foo",
                    Document(
                        "bar")
                )
            )
            ,
            stringValue: "string"
        )
        let mockSerializeStackStep: MockSerializeStackStep<InlineDocumentInput> = constructMockSerializeStackStep(interceptCallback: {
            var step = SerializeStep<InlineDocumentInput>()
            step.intercept(position: .before, middleware: InlineDocumentInputHeadersMiddleware())
            step.intercept(position: .before, middleware: InlineDocumentInputQueryItemMiddleware())
            step.intercept(position: .before, middleware: InlineDocumentInputBodyMiddleware())
            step.intercept(position: .before, middleware: ContentTypeMiddleware<InlineDocumentInput>(contentType: "application/json"))
            return step
        })
        let mockBuildStackStep: MockBuildStackStep<InlineDocumentInput> = constructMockBuildStackStep(interceptCallback: {
            var step = BuildStep<InlineDocumentInput>()
            step.intercept(position: .before, middleware: ContentLengthMiddleware<InlineDocumentInput>())
            return step
        })
        let mockDeserializeStackStep: MockDeserializeStackStep<MockOutput, MockMiddlewareError> = constructMockDeserializeStackStep(interceptCallback: {
            var step = DeserializeStep<MockOutput, MockMiddlewareError>()
            step.intercept(position: .after,
                         middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(
                                 id: "TestDeserializeMiddleware"){ context, actual in
                self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                    XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                    XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                    self.assertEqualHttpBodyJSONData(expectedHttpBody!, actualHttpBody!)
                })
                let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
                let mockOutput = try! MockOutput(httpResponse: response, decoder: nil)
                let output = DeserializeOutput<MockOutput, MockMiddlewareError>(httpResponse: response, output: mockOutput)
                deserializeMiddleware.fulfill()
                return .success(output)
            })
            return step
        })
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        let operationStack = OperationStack<InlineDocumentInput, MockOutput, MockMiddlewareError>(id: "InlineDocumentInput",
        serializeStackStep: mockSerializeStackStep,
        buildStackStep: mockBuildStackStep,
        deserializeStackStep: mockDeserializeStackStep)
        _ = operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            return .failure(try! MockMiddlewareError(httpResponse: HttpResponse(body: .none, statusCode: .badRequest)))
        })
        wait(for: [deserializeMiddleware], timeout: 0.3)
 """
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for inline document as payload`() {
        val contents = getTestFileContents("example", "InlineDocumentAsPayloadRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testInlineDocumentAsPayloadInput() {
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/InlineDocumentAsPayload",
            headers: [
                "Content-Type": "application/json"
            ],
            queryParams: [String](),
            body: ""${'"'}
            {
                "foo": "bar"
            }
            ""${'"'},
            host: host
        )

        let deserializeMiddleware = expectation(description: "deserializeMiddleware")

        let input = InlineDocumentAsPayloadInput(
            documentValue: Document(
                dictionaryLiteral:
                (
                    "foo",
                    Document(
                        "bar")
                )
            )

        )
        let mockSerializeStackStep: MockSerializeStackStep<InlineDocumentAsPayloadInput> = constructMockSerializeStackStep(interceptCallback: {
            var step = SerializeStep<InlineDocumentAsPayloadInput>()
            step.intercept(position: .before, middleware: InlineDocumentAsPayloadInputHeadersMiddleware())
            step.intercept(position: .before, middleware: InlineDocumentAsPayloadInputQueryItemMiddleware())
            step.intercept(position: .before, middleware: InlineDocumentAsPayloadInputBodyMiddleware())
            step.intercept(position: .before, middleware: ContentTypeMiddleware<InlineDocumentAsPayloadInput>(contentType: "application/json"))
            return step
        })
        let mockBuildStackStep: MockBuildStackStep<InlineDocumentAsPayloadInput> = constructMockBuildStackStep(interceptCallback: {
            var step = BuildStep<InlineDocumentAsPayloadInput>()
            step.intercept(position: .before, middleware: ContentLengthMiddleware<InlineDocumentAsPayloadInput>())
            return step
        })
        let mockDeserializeStackStep: MockDeserializeStackStep<MockOutput, MockMiddlewareError> = constructMockDeserializeStackStep(interceptCallback: {
            var step = DeserializeStep<MockOutput, MockMiddlewareError>()
            step.intercept(position: .after,
                         middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(
                                 id: "TestDeserializeMiddleware"){ context, actual in
                self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                    XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                    XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                    self.assertEqualHttpBodyJSONData(expectedHttpBody!, actualHttpBody!)
                })
                let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
                let mockOutput = try! MockOutput(httpResponse: response, decoder: nil)
                let output = DeserializeOutput<MockOutput, MockMiddlewareError>(httpResponse: response, output: mockOutput)
                deserializeMiddleware.fulfill()
                return .success(output)
            })
            return step
        })
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        let operationStack = OperationStack<InlineDocumentAsPayloadInput, MockOutput, MockMiddlewareError>(id: "InlineDocumentAsPayloadInput",
        serializeStackStep: mockSerializeStackStep,
        buildStackStep: mockBuildStackStep,
        deserializeStackStep: mockDeserializeStackStep)
        _ = operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            return .failure(try! MockMiddlewareError(httpResponse: HttpResponse(body: .none, statusCode: .badRequest)))
        })
        wait(for: [deserializeMiddleware], timeout: 0.3)
 """
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
