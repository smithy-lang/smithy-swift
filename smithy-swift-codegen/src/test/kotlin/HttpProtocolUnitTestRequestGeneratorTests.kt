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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        var operationStack = OperationStack<SmokeTestInput, SmokeTestOutput, SmokeTestError>(id: "SmokeTest")
        operationStack.serializeStep.intercept(position: .before, middleware: SmokeTestInputHeadersMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: SmokeTestInputQueryItemMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: SmokeTestInputBodyMiddleware())
        operationStack.buildStep.intercept(position: .before, middleware: ContentLengthMiddleware<SmokeTestOutput, SmokeTestError>())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<SmokeTestOutput, SmokeTestError>(
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
            let mockOutput = try! SmokeTestOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<SmokeTestOutput, SmokeTestError>(httpResponse: response, output: mockOutput)
            deserializeMiddleware.fulfill()
            return .success(output)
        })
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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        var operationStack = OperationStack<ExplicitStringInput, ExplicitStringOutput, ExplicitStringError>(id: "ExplicitString")
        operationStack.serializeStep.intercept(position: .before, middleware: ExplicitStringInputHeadersMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: ExplicitStringInputQueryItemMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: ExplicitStringInputBodyMiddleware())
        operationStack.buildStep.intercept(position: .before, middleware: ContentLengthMiddleware<ExplicitStringOutput, ExplicitStringError>())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<ExplicitStringOutput, ExplicitStringError>(
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
            let mockOutput = try! ExplicitStringOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<ExplicitStringOutput, ExplicitStringError>(httpResponse: response, output: mockOutput)
            deserializeMiddleware.fulfill()
            return .success(output)
        })
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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        var operationStack = OperationStack<EmptyInputAndEmptyOutputInput, EmptyInputAndEmptyOutputOutput, EmptyInputAndEmptyOutputError>(id: "RestJsonEmptyInputAndEmptyOutput")
        operationStack.serializeStep.intercept(position: .before, middleware: EmptyInputAndEmptyOutputInputHeadersMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: EmptyInputAndEmptyOutputInputQueryItemMiddleware())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<EmptyInputAndEmptyOutputOutput, EmptyInputAndEmptyOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssert(actualHttpBody == HttpBody.none, "The actual HttpBody is not none as expected")
                XCTAssert(expectedHttpBody == HttpBody.none, "The expected HttpBody is not none as expected")
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! EmptyInputAndEmptyOutputOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<EmptyInputAndEmptyOutputOutput, EmptyInputAndEmptyOutputError>(httpResponse: response, output: mockOutput)
            deserializeMiddleware.fulfill()
            return .success(output)
        })
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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        var operationStack = OperationStack<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutput, SimpleScalarPropertiesError>(id: "RestJsonDoesntSerializeNullStructureValues")
        operationStack.serializeStep.intercept(position: .before, middleware: SimpleScalarPropertiesInputHeadersMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: SimpleScalarPropertiesInputQueryItemMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: SimpleScalarPropertiesInputBodyMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: ContentTypeMiddleware<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutput, SimpleScalarPropertiesError>(contentType: "application/json"))
        operationStack.buildStep.intercept(position: .before, middleware: ContentLengthMiddleware<SimpleScalarPropertiesOutput, SimpleScalarPropertiesError>())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<SimpleScalarPropertiesOutput, SimpleScalarPropertiesError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssert(actualHttpBody == HttpBody.none, "The actual HttpBody is not none as expected")
                XCTAssert(expectedHttpBody == HttpBody.none, "The expected HttpBody is not none as expected")
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! SimpleScalarPropertiesOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<SimpleScalarPropertiesOutput, SimpleScalarPropertiesError>(httpResponse: response, output: mockOutput)
            deserializeMiddleware.fulfill()
            return .success(output)
        })
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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        var operationStack = OperationStack<StreamingTraitsInput, StreamingTraitsOutput, StreamingTraitsError>(id: "RestJsonStreamingTraitsWithBlob")
        operationStack.serializeStep.intercept(position: .before, middleware: StreamingTraitsInputHeadersMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: StreamingTraitsInputQueryItemMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: StreamingTraitsInputBodyMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: ContentTypeMiddleware<StreamingTraitsInput, StreamingTraitsOutput, StreamingTraitsError>(contentType: "application/octet-stream"))
        operationStack.buildStep.intercept(position: .before, middleware: ContentLengthMiddleware<StreamingTraitsOutput, StreamingTraitsError>())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<StreamingTraitsOutput, StreamingTraitsError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                self.assertEqualHttpBodyData(expectedHttpBody!, actualHttpBody!)
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! StreamingTraitsOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<StreamingTraitsOutput, StreamingTraitsError>(httpResponse: response, output: mockOutput)
            deserializeMiddleware.fulfill()
            return .success(output)
        })
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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        var operationStack = OperationStack<HttpPrefixHeadersInput, HttpPrefixHeadersOutput, HttpPrefixHeadersError>(id: "RestJsonHttpPrefixHeadersAreNotPresent")
        operationStack.serializeStep.intercept(position: .before, middleware: HttpPrefixHeadersInputHeadersMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: HttpPrefixHeadersInputQueryItemMiddleware())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<HttpPrefixHeadersOutput, HttpPrefixHeadersError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssert(actualHttpBody == HttpBody.none, "The actual HttpBody is not none as expected")
                XCTAssert(expectedHttpBody == HttpBody.none, "The expected HttpBody is not none as expected")
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! HttpPrefixHeadersOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<HttpPrefixHeadersOutput, HttpPrefixHeadersError>(httpResponse: response, output: mockOutput)
            deserializeMiddleware.fulfill()
            return .success(output)
        })
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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        var operationStack = OperationStack<JsonUnionsInput, JsonUnionsOutput, JsonUnionsError>(id: "RestJsonSerializeStringUnionValue")
        operationStack.serializeStep.intercept(position: .before, middleware: JsonUnionsInputHeadersMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: JsonUnionsInputQueryItemMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: JsonUnionsInputBodyMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: ContentTypeMiddleware<JsonUnionsInput, JsonUnionsOutput, JsonUnionsError>(contentType: "application/json"))
        operationStack.buildStep.intercept(position: .before, middleware: ContentLengthMiddleware<JsonUnionsOutput, JsonUnionsError>())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<JsonUnionsOutput, JsonUnionsError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                self.assertEqualHttpBodyJSONData(expectedHttpBody!, actualHttpBody!)
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! JsonUnionsOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<JsonUnionsOutput, JsonUnionsError>(httpResponse: response, output: mockOutput)
            deserializeMiddleware.fulfill()
            return .success(output)
        })
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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        var operationStack = OperationStack<RecursiveShapesInput, RecursiveShapesOutput, RecursiveShapesError>(id: "RestJsonRecursiveShapes")
        operationStack.serializeStep.intercept(position: .before, middleware: RecursiveShapesInputHeadersMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: RecursiveShapesInputQueryItemMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: RecursiveShapesInputBodyMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: ContentTypeMiddleware<RecursiveShapesInput, RecursiveShapesOutput, RecursiveShapesError>(contentType: "application/json"))
        operationStack.buildStep.intercept(position: .before, middleware: ContentLengthMiddleware<RecursiveShapesOutput, RecursiveShapesError>())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<RecursiveShapesOutput, RecursiveShapesError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                self.assertEqualHttpBodyJSONData(expectedHttpBody!, actualHttpBody!)
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! RecursiveShapesOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<RecursiveShapesOutput, RecursiveShapesError>(httpResponse: response, output: mockOutput)
            deserializeMiddleware.fulfill()
            return .success(output)
        })
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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        var operationStack = OperationStack<InlineDocumentInput, InlineDocumentOutput, InlineDocumentError>(id: "InlineDocumentInput")
        operationStack.serializeStep.intercept(position: .before, middleware: InlineDocumentInputHeadersMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: InlineDocumentInputQueryItemMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: InlineDocumentInputBodyMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: ContentTypeMiddleware<InlineDocumentInput, InlineDocumentOutput, InlineDocumentError>(contentType: "application/json"))
        operationStack.buildStep.intercept(position: .before, middleware: ContentLengthMiddleware<InlineDocumentOutput, InlineDocumentError>())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<InlineDocumentOutput, InlineDocumentError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                self.assertEqualHttpBodyJSONData(expectedHttpBody!, actualHttpBody!)
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! InlineDocumentOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<InlineDocumentOutput, InlineDocumentError>(httpResponse: response, output: mockOutput)
            deserializeMiddleware.fulfill()
            return .success(output)
        })
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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        var operationStack = OperationStack<InlineDocumentAsPayloadInput, InlineDocumentAsPayloadOutput, InlineDocumentAsPayloadError>(id: "InlineDocumentAsPayloadInput")
        operationStack.serializeStep.intercept(position: .before, middleware: InlineDocumentAsPayloadInputHeadersMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: InlineDocumentAsPayloadInputQueryItemMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: InlineDocumentAsPayloadInputBodyMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: ContentTypeMiddleware<InlineDocumentAsPayloadInput, InlineDocumentAsPayloadOutput, InlineDocumentAsPayloadError>(contentType: "application/json"))
        operationStack.buildStep.intercept(position: .before, middleware: ContentLengthMiddleware<InlineDocumentAsPayloadOutput, InlineDocumentAsPayloadError>())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<InlineDocumentAsPayloadOutput, InlineDocumentAsPayloadError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                self.assertEqualHttpBodyJSONData(expectedHttpBody!, actualHttpBody!)
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! InlineDocumentAsPayloadOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<InlineDocumentAsPayloadOutput, InlineDocumentAsPayloadError>(httpResponse: response, output: mockOutput)
            deserializeMiddleware.fulfill()
            return .success(output)
        })
        _ = operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            return .failure(try! MockMiddlewareError(httpResponse: HttpResponse(body: .none, statusCode: .badRequest)))
        })
        wait(for: [deserializeMiddleware], timeout: 0.3)
 """
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
