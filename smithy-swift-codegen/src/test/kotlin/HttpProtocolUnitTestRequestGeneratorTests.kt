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

        val expectedContents =
            """
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
            host: "",
            resolvedHost: ""
        )

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")

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
        let encoder = ClientRuntime.JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .withMethod(value: .post)
                      .build()
        var operationStack = OperationStack<SmokeTestInput, SmokeTestOutputResponse, SmokeTestOutputError>(id: "SmokeTest")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<SmokeTestInput, SmokeTestOutputResponse, SmokeTestOutputError>(urlPrefix: urlPrefix))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<SmokeTestInput, SmokeTestOutputResponse>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<SmokeTestOutputResponse> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.HeaderMiddleware<SmokeTestInput, SmokeTestOutputResponse>())
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.QueryItemMiddleware<SmokeTestInput, SmokeTestOutputResponse>())
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<SmokeTestInput, SmokeTestOutputResponse>(contentType: "application/json"))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.SerializableBodyMiddleware<SmokeTestInput, SmokeTestOutputResponse>())
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<SmokeTestOutputResponse, SmokeTestOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                self.genericAssertEqualHttpBodyData(expectedHttpBody!, actualHttpBody!) { expectedData, actualData in
                    do {
                        let expectedObj = try decoder.decode(SmokeTestInputBody.self, from: expectedData)
                        let actualObj = try decoder.decode(SmokeTestInputBody.self, from: actualData)
                        XCTAssertEqual(expectedObj.label1, actualObj.label1)
                        XCTAssertEqual(expectedObj.payload1, actualObj.payload1)
                        XCTAssertEqual(expectedObj.payload2, actualObj.payload2)
                        XCTAssertEqual(expectedObj.payload3, actualObj.payload3)
                    } catch let err {
                        XCTFail("Failed to verify body \(err)")
                    }
                }
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! SmokeTestOutputResponse(httpResponse: response, decoder: nil)
            let output = OperationOutput<SmokeTestOutputResponse>(httpResponse: response, output: mockOutput)
            return output
        })
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
            let serviceError = try! SmokeTestOutputError(httpResponse: httpResponse)
            throw SdkError<SmokeTestOutputError>.service(serviceError, httpResponse)
        })
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
    func testExplicitString() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .post,
            path: "/explicit/string",
            requiredHeaders: [
                "Content-Length"
            ],
            body: ""${'"'}
            {
            "payload1": "explicit string"
            }
            ""${'"'},
            host: "",
            resolvedHost: ""
        )

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")

        let input = ExplicitStringInput(
            payload1: "explicit string"
        )
        let encoder = ClientRuntime.JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .withMethod(value: .post)
                      .build()
        var operationStack = OperationStack<ExplicitStringInput, ExplicitStringOutputResponse, ExplicitStringOutputError>(id: "ExplicitString")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<ExplicitStringInput, ExplicitStringOutputResponse, ExplicitStringOutputError>(urlPrefix: urlPrefix))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<ExplicitStringInput, ExplicitStringOutputResponse>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<ExplicitStringOutputResponse> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<ExplicitStringInput, ExplicitStringOutputResponse>(contentType: "text/plain"))
        operationStack.serializeStep.intercept(position: .after, middleware: ExplicitStringInputBodyMiddleware())
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<ExplicitStringOutputResponse, ExplicitStringOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                self.genericAssertEqualHttpBodyData(expectedHttpBody!, actualHttpBody!) { expectedData, actualData in
                    XCTAssertEqual(expectedData, actualData)
                }
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! ExplicitStringOutputResponse(httpResponse: response, decoder: nil)
            let output = OperationOutput<ExplicitStringOutputResponse>(httpResponse: response, output: mockOutput)
            return output
        })
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
            let serviceError = try! ExplicitStringOutputError(httpResponse: httpResponse)
            throw SdkError<ExplicitStringOutputError>.service(serviceError, httpResponse)
        })
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

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")

        let input = EmptyInputAndEmptyOutputInput(
        )
        let encoder = ClientRuntime.JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .withMethod(value: .post)
                      .build()
        var operationStack = OperationStack<EmptyInputAndEmptyOutputInput, EmptyInputAndEmptyOutputOutputResponse, EmptyInputAndEmptyOutputOutputError>(id: "RestJsonEmptyInputAndEmptyOutput")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<EmptyInputAndEmptyOutputInput, EmptyInputAndEmptyOutputOutputResponse, EmptyInputAndEmptyOutputOutputError>(urlPrefix: urlPrefix))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<EmptyInputAndEmptyOutputInput, EmptyInputAndEmptyOutputOutputResponse>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<EmptyInputAndEmptyOutputOutputResponse> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<EmptyInputAndEmptyOutputOutputResponse, EmptyInputAndEmptyOutputOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssert(actualHttpBody == HttpBody.none, "The actual HttpBody is not none as expected")
                XCTAssert(expectedHttpBody == HttpBody.none, "The expected HttpBody is not none as expected")
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! EmptyInputAndEmptyOutputOutputResponse(httpResponse: response, decoder: nil)
            let output = OperationOutput<EmptyInputAndEmptyOutputOutputResponse>(httpResponse: response, output: mockOutput)
            return output
        })
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
            let serviceError = try! EmptyInputAndEmptyOutputOutputError(httpResponse: httpResponse)
            throw SdkError<EmptyInputAndEmptyOutputOutputError>.service(serviceError, httpResponse)
        })
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
    func testRestJsonDoesntSerializeNullStructureValues() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/SimpleScalarProperties",
            headers: [
                "Content-Type": "application/json"
            ],
            body: nil,
            host: "",
            resolvedHost: ""
        )

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")

        let input = SimpleScalarPropertiesInput(
            stringValue: nil
        )
        let encoder = ClientRuntime.JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .withMethod(value: .put)
                      .build()
        var operationStack = OperationStack<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutputResponse, SimpleScalarPropertiesOutputError>(id: "RestJsonDoesntSerializeNullStructureValues")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutputResponse, SimpleScalarPropertiesOutputError>(urlPrefix: urlPrefix))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutputResponse>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<SimpleScalarPropertiesOutputResponse> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.HeaderMiddleware<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutputResponse>())
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutputResponse>(contentType: "application/json"))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.SerializableBodyMiddleware<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutputResponse>())
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<SimpleScalarPropertiesOutputResponse, SimpleScalarPropertiesOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssert(actualHttpBody == HttpBody.none, "The actual HttpBody is not none as expected")
                XCTAssert(expectedHttpBody == HttpBody.none, "The expected HttpBody is not none as expected")
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! SimpleScalarPropertiesOutputResponse(httpResponse: response, decoder: nil)
            let output = OperationOutput<SimpleScalarPropertiesOutputResponse>(httpResponse: response, output: mockOutput)
            return output
        })
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
            let serviceError = try! SimpleScalarPropertiesOutputError(httpResponse: httpResponse)
            throw SdkError<SimpleScalarPropertiesOutputError>.service(serviceError, httpResponse)
        })
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
            body: ""${'"'}
            blobby blob blob
            ""${'"'},
            host: "",
            resolvedHost: ""
        )

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")

        let input = StreamingTraitsInput(
            blob: ByteStream.from(data: "blobby blob blob".data(using: .utf8)!),
            foo: "Foo"
        )
        let encoder = ClientRuntime.JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .withMethod(value: .post)
                      .build()
        var operationStack = OperationStack<StreamingTraitsInput, StreamingTraitsOutputResponse, StreamingTraitsOutputError>(id: "RestJsonStreamingTraitsWithBlob")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<StreamingTraitsInput, StreamingTraitsOutputResponse, StreamingTraitsOutputError>(urlPrefix: urlPrefix))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<StreamingTraitsInput, StreamingTraitsOutputResponse>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<StreamingTraitsOutputResponse> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.HeaderMiddleware<StreamingTraitsInput, StreamingTraitsOutputResponse>())
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<StreamingTraitsInput, StreamingTraitsOutputResponse>(contentType: "application/octet-stream"))
        operationStack.serializeStep.intercept(position: .after, middleware: StreamingTraitsInputBodyMiddleware())
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<StreamingTraitsOutputResponse, StreamingTraitsOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                self.genericAssertEqualHttpBodyData(expectedHttpBody!, actualHttpBody!) { expectedData, actualData in
                    XCTAssertEqual(expectedData, actualData)
                }
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! StreamingTraitsOutputResponse(httpResponse: response, decoder: nil)
            let output = OperationOutput<StreamingTraitsOutputResponse>(httpResponse: response, output: mockOutput)
            return output
        })
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
            let serviceError = try! StreamingTraitsOutputError(httpResponse: httpResponse)
            throw SdkError<StreamingTraitsOutputError>.service(serviceError, httpResponse)
        })
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

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")

        let input = HttpPrefixHeadersInput(
            foo: "Foo",
            fooMap: [:]

        )
        let encoder = ClientRuntime.JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .withMethod(value: .get)
                      .build()
        var operationStack = OperationStack<HttpPrefixHeadersInput, HttpPrefixHeadersOutputResponse, HttpPrefixHeadersOutputError>(id: "RestJsonHttpPrefixHeadersAreNotPresent")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<HttpPrefixHeadersInput, HttpPrefixHeadersOutputResponse, HttpPrefixHeadersOutputError>(urlPrefix: urlPrefix))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<HttpPrefixHeadersInput, HttpPrefixHeadersOutputResponse>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<HttpPrefixHeadersOutputResponse> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.HeaderMiddleware<HttpPrefixHeadersInput, HttpPrefixHeadersOutputResponse>())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<HttpPrefixHeadersOutputResponse, HttpPrefixHeadersOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssert(actualHttpBody == HttpBody.none, "The actual HttpBody is not none as expected")
                XCTAssert(expectedHttpBody == HttpBody.none, "The expected HttpBody is not none as expected")
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! HttpPrefixHeadersOutputResponse(httpResponse: response, decoder: nil)
            let output = OperationOutput<HttpPrefixHeadersOutputResponse>(httpResponse: response, output: mockOutput)
            return output
        })
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
            let serviceError = try! HttpPrefixHeadersOutputError(httpResponse: httpResponse)
            throw SdkError<HttpPrefixHeadersOutputError>.service(serviceError, httpResponse)
        })
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
    func testRestJsonSerializeStringUnionValue() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/JsonUnions",
            headers: [
                "Content-Type": "application/json"
            ],
            body: ""${'"'}
            {
                "contents": {
                    "stringValue": "foo"
                }
            }
            ""${'"'},
            host: "",
            resolvedHost: ""
        )

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")

        let input = JsonUnionsInput(
            contents: MyUnion.stringvalue("foo")

        )
        let encoder = ClientRuntime.JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .withMethod(value: .put)
                      .build()
        var operationStack = OperationStack<JsonUnionsInput, JsonUnionsOutputResponse, JsonUnionsOutputError>(id: "RestJsonSerializeStringUnionValue")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<JsonUnionsInput, JsonUnionsOutputResponse, JsonUnionsOutputError>(urlPrefix: urlPrefix))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<JsonUnionsInput, JsonUnionsOutputResponse>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<JsonUnionsOutputResponse> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<JsonUnionsInput, JsonUnionsOutputResponse>(contentType: "application/json"))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.SerializableBodyMiddleware<JsonUnionsInput, JsonUnionsOutputResponse>())
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<JsonUnionsOutputResponse, JsonUnionsOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                self.genericAssertEqualHttpBodyData(expectedHttpBody!, actualHttpBody!) { expectedData, actualData in
                    do {
                        let expectedObj = try decoder.decode(JsonUnionsInputBody.self, from: expectedData)
                        let actualObj = try decoder.decode(JsonUnionsInputBody.self, from: actualData)
                        XCTAssertEqual(expectedObj.contents, actualObj.contents)
                    } catch let err {
                        XCTFail("Failed to verify body \(err)")
                    }
                }
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! JsonUnionsOutputResponse(httpResponse: response, decoder: nil)
            let output = OperationOutput<JsonUnionsOutputResponse>(httpResponse: response, output: mockOutput)
            return output
        })
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
            let serviceError = try! JsonUnionsOutputError(httpResponse: httpResponse)
            throw SdkError<JsonUnionsOutputError>.service(serviceError, httpResponse)
        })
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
    func testRestJsonRecursiveShapes() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/RecursiveShapes",
            headers: [
                "Content-Type": "application/json"
            ],
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
            host: "",
            resolvedHost: ""
        )

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")

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
        let encoder = ClientRuntime.JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .withMethod(value: .put)
                      .build()
        var operationStack = OperationStack<RecursiveShapesInput, RecursiveShapesOutputResponse, RecursiveShapesOutputError>(id: "RestJsonRecursiveShapes")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<RecursiveShapesInput, RecursiveShapesOutputResponse, RecursiveShapesOutputError>(urlPrefix: urlPrefix))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<RecursiveShapesInput, RecursiveShapesOutputResponse>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<RecursiveShapesOutputResponse> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<RecursiveShapesInput, RecursiveShapesOutputResponse>(contentType: "application/json"))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.SerializableBodyMiddleware<RecursiveShapesInput, RecursiveShapesOutputResponse>())
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<RecursiveShapesOutputResponse, RecursiveShapesOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                self.genericAssertEqualHttpBodyData(expectedHttpBody!, actualHttpBody!) { expectedData, actualData in
                    do {
                        let expectedObj = try decoder.decode(RecursiveShapesInputBody.self, from: expectedData)
                        let actualObj = try decoder.decode(RecursiveShapesInputBody.self, from: actualData)
                        XCTAssertEqual(expectedObj.nested, actualObj.nested)
                    } catch let err {
                        XCTFail("Failed to verify body \(err)")
                    }
                }
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! RecursiveShapesOutputResponse(httpResponse: response, decoder: nil)
            let output = OperationOutput<RecursiveShapesOutputResponse>(httpResponse: response, output: mockOutput)
            return output
        })
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
            let serviceError = try! RecursiveShapesOutputError(httpResponse: httpResponse)
            throw SdkError<RecursiveShapesOutputError>.service(serviceError, httpResponse)
        })
 """
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for inline document`() {
        val contents = getTestFileContents("example", "InlineDocumentRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testInlineDocumentInput() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/InlineDocument",
            headers: [
                "Content-Type": "application/json"
            ],
            body: ""${'"'}
            {
                "stringValue": "string",
                "documentValue": {
                    "foo": "bar"
                }
            }
            ""${'"'},
            host: "",
            resolvedHost: ""
        )

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")

        let input = InlineDocumentInput(
            documentValue: try decoder.decode(Document.self, from:
                ""${'"'}
                {
                    "foo": "bar"
                }
                ""${'"'}.data(using: .utf8)!)
                ,
                stringValue: "string"
            )
            let encoder = ClientRuntime.JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
            let context = HttpContextBuilder()
                          .withEncoder(value: encoder)
                          .withMethod(value: .put)
                          .build()
            var operationStack = OperationStack<InlineDocumentInput, InlineDocumentOutputResponse, InlineDocumentOutputError>(id: "InlineDocumentInput")
            operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<InlineDocumentInput, InlineDocumentOutputResponse, InlineDocumentOutputError>(urlPrefix: urlPrefix))
            operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<InlineDocumentInput, InlineDocumentOutputResponse>(host: hostOnly))
            operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<InlineDocumentOutputResponse> in
                input.withMethod(context.getMethod())
                input.withPath(context.getPath())
                let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
                input.withHost(host)
                return try await next.handle(context: context, input: input)
            }
            operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<InlineDocumentInput, InlineDocumentOutputResponse>(contentType: "application/json"))
            operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.SerializableBodyMiddleware<InlineDocumentInput, InlineDocumentOutputResponse>())
            operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
            operationStack.deserializeStep.intercept(position: .after,
                         middleware: MockDeserializeMiddleware<InlineDocumentOutputResponse, InlineDocumentOutputError>(
                                 id: "TestDeserializeMiddleware"){ context, actual in
                self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                    XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                    XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                    self.genericAssertEqualHttpBodyData(expectedHttpBody!, actualHttpBody!) { expectedData, actualData in
                        do {
                            let expectedObj = try decoder.decode(InlineDocumentInputBody.self, from: expectedData)
                            let actualObj = try decoder.decode(InlineDocumentInputBody.self, from: actualData)
                            XCTAssertEqual(expectedObj.stringValue, actualObj.stringValue)
                            XCTAssertEqual(expectedObj.documentValue, actualObj.documentValue)
                        } catch let err {
                            XCTFail("Failed to verify body \(err)")
                        }
                    }
                })
                let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
                let mockOutput = try! InlineDocumentOutputResponse(httpResponse: response, decoder: nil)
                let output = OperationOutput<InlineDocumentOutputResponse>(httpResponse: response, output: mockOutput)
                return output
            })
            _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
                XCTFail("Deserialize was mocked out, this should fail")
                let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
                let serviceError = try! InlineDocumentOutputError(httpResponse: httpResponse)
                throw SdkError<InlineDocumentOutputError>.service(serviceError, httpResponse)
            })
        }
 """
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for inline document as payload`() {
        val contents = getTestFileContents("example", "InlineDocumentAsPayloadRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testInlineDocumentAsPayloadInput() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/InlineDocumentAsPayload",
            headers: [
                "Content-Type": "application/json"
            ],
            body: ""${'"'}
            {
                "foo": "bar"
            }
            ""${'"'},
            host: "",
            resolvedHost: ""
        )

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")

        let input = InlineDocumentAsPayloadInput(
            documentValue: try decoder.decode(Document.self, from:
                ""${'"'}
                {
                    "foo": "bar"
                }
                ""${'"'}.data(using: .utf8)!)

            )
            let encoder = ClientRuntime.JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
            let context = HttpContextBuilder()
                          .withEncoder(value: encoder)
                          .withMethod(value: .put)
                          .build()
            var operationStack = OperationStack<InlineDocumentAsPayloadInput, InlineDocumentAsPayloadOutputResponse, InlineDocumentAsPayloadOutputError>(id: "InlineDocumentAsPayloadInput")
            operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<InlineDocumentAsPayloadInput, InlineDocumentAsPayloadOutputResponse, InlineDocumentAsPayloadOutputError>(urlPrefix: urlPrefix))
            operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<InlineDocumentAsPayloadInput, InlineDocumentAsPayloadOutputResponse>(host: hostOnly))
            operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<InlineDocumentAsPayloadOutputResponse> in
                input.withMethod(context.getMethod())
                input.withPath(context.getPath())
                let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
                input.withHost(host)
                return try await next.handle(context: context, input: input)
            }
            operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<InlineDocumentAsPayloadInput, InlineDocumentAsPayloadOutputResponse>(contentType: "application/json"))
            operationStack.serializeStep.intercept(position: .after, middleware: InlineDocumentAsPayloadInputBodyMiddleware())
            operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
            operationStack.deserializeStep.intercept(position: .after,
                         middleware: MockDeserializeMiddleware<InlineDocumentAsPayloadOutputResponse, InlineDocumentAsPayloadOutputError>(
                                 id: "TestDeserializeMiddleware"){ context, actual in
                self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                    XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                    XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                    self.genericAssertEqualHttpBodyData(expectedHttpBody!, actualHttpBody!) { expectedData, actualData in
                        do {
                            let expectedObj = try decoder.decode(ClientRuntime.Document.self, from: expectedData)
                            let actualObj = try decoder.decode(ClientRuntime.Document.self, from: actualData)
                            XCTAssertEqual(expectedObj, actualObj)
                        } catch let err {
                            XCTFail("Failed to verify body \(err)")
                        }
                    }
                })
                let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
                let mockOutput = try! InlineDocumentAsPayloadOutputResponse(httpResponse: response, decoder: nil)
                let output = OperationOutput<InlineDocumentAsPayloadOutputResponse>(httpResponse: response, output: mockOutput)
                return output
            })
            _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
                XCTFail("Deserialize was mocked out, this should fail")
                let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
                let serviceError = try! InlineDocumentAsPayloadOutputError(httpResponse: httpResponse)
                throw SdkError<InlineDocumentAsPayloadOutputError>.service(serviceError, httpResponse)
            })
        }
 """
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
