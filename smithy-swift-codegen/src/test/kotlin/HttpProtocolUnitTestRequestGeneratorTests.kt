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
            body: .data( ""${'"'}
            {
            "payload1": "String",
            "payload2": 2,
            "payload3": {
                "member1": "test string",
                "member2": "test string 2"
                }
            }
            ""${'"'}.data(using: .utf8)!),
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
        var operationStack = OperationStack<SmokeTestInput, SmokeTestOutput>(id: "SmokeTest")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<SmokeTestInput, SmokeTestOutput>(urlPrefix: urlPrefix))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<SmokeTestInput, SmokeTestOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<SmokeTestOutput> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.HeaderMiddleware<SmokeTestInput, SmokeTestOutput>())
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.QueryItemMiddleware<SmokeTestInput, SmokeTestOutput>())
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<SmokeTestInput, SmokeTestOutput>(contentType: "application/json"))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.BodyMiddleware<SmokeTestInput, SmokeTestOutput, ClientRuntime.JSONWriter>(documentWritingClosure: ClientRuntime.JSONReadWrite.documentWritingClosure(encoder: encoder), inputWritingClosure: JSONReadWrite.writingClosure()))
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<SmokeTestOutput, SmokeTestOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, isXML: false, isJSON: true) { expectedData, actualData in
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
            let mockOutput = try await SmokeTestOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<SmokeTestOutput>(httpResponse: response, output: mockOutput)
            return output
        })
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
            let serviceError = try await SmokeTestOutputError.makeError(httpResponse: httpResponse, decoder: decoder)
            throw serviceError
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
            body: .data( ""${'"'}
            {
            "payload1": "explicit string"
            }
            ""${'"'}.data(using: .utf8)!),
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
        var operationStack = OperationStack<ExplicitStringInput, ExplicitStringOutput>(id: "ExplicitString")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<ExplicitStringInput, ExplicitStringOutput>(urlPrefix: urlPrefix))
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
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<ExplicitStringOutput, ExplicitStringOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, isXML: false, isJSON: true) { expectedData, actualData in
                    XCTAssertEqual(expectedData, actualData)
                }
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try await ExplicitStringOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<ExplicitStringOutput>(httpResponse: response, output: mockOutput)
            return output
        })
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
            let serviceError = try await ExplicitStringOutputError.makeError(httpResponse: httpResponse, decoder: decoder)
            throw serviceError
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
        var operationStack = OperationStack<EmptyInputAndEmptyOutputInput, EmptyInputAndEmptyOutputOutput>(id: "RestJsonEmptyInputAndEmptyOutput")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<EmptyInputAndEmptyOutputInput, EmptyInputAndEmptyOutputOutput>(urlPrefix: urlPrefix))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<EmptyInputAndEmptyOutputInput, EmptyInputAndEmptyOutputOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<EmptyInputAndEmptyOutputOutput> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<EmptyInputAndEmptyOutputOutput, EmptyInputAndEmptyOutputOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            try await self.assertEqual(expected, actual)
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try await EmptyInputAndEmptyOutputOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<EmptyInputAndEmptyOutputOutput>(httpResponse: response, output: mockOutput)
            return output
        })
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
            let serviceError = try await EmptyInputAndEmptyOutputOutputError.makeError(httpResponse: httpResponse, decoder: decoder)
            throw serviceError
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
            body: .data( ""${'"'}
            {}
            ""${'"'}.data(using: .utf8)!),
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
        var operationStack = OperationStack<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutput>(id: "RestJsonDoesntSerializeNullStructureValues")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutput>(urlPrefix: urlPrefix))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<SimpleScalarPropertiesOutput> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.HeaderMiddleware<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutput>())
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutput>(contentType: "application/json"))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.BodyMiddleware<SimpleScalarPropertiesInput, SimpleScalarPropertiesOutput, ClientRuntime.JSONWriter>(documentWritingClosure: ClientRuntime.JSONReadWrite.documentWritingClosure(encoder: encoder), inputWritingClosure: JSONReadWrite.writingClosure()))
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<SimpleScalarPropertiesOutput, SimpleScalarPropertiesOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, isXML: false, isJSON: true) { expectedData, actualData in
                    do {
                        let expectedObj = try decoder.decode(SimpleScalarPropertiesInputBody.self, from: expectedData)
                        let actualObj = try decoder.decode(SimpleScalarPropertiesInputBody.self, from: actualData)
                        XCTAssertEqual(expectedObj.stringValue, actualObj.stringValue)
                        XCTAssertEqual(expectedObj.trueBooleanValue, actualObj.trueBooleanValue)
                        XCTAssertEqual(expectedObj.falseBooleanValue, actualObj.falseBooleanValue)
                        XCTAssertEqual(expectedObj.byteValue, actualObj.byteValue)
                        XCTAssertEqual(expectedObj.shortValue, actualObj.shortValue)
                        XCTAssertEqual(expectedObj.integerValue, actualObj.integerValue)
                        XCTAssertEqual(expectedObj.longValue, actualObj.longValue)
                        XCTAssertEqual(expectedObj.floatValue, actualObj.floatValue)
                        XCTAssertEqual(expectedObj.doubleValue, actualObj.doubleValue)
                    } catch let err {
                        XCTFail("Failed to verify body \(err)")
                    }
                }
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try await SimpleScalarPropertiesOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<SimpleScalarPropertiesOutput>(httpResponse: response, output: mockOutput)
            return output
        })
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
            let serviceError = try await SimpleScalarPropertiesOutputError.makeError(httpResponse: httpResponse, decoder: decoder)
            throw serviceError
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
            body: .stream(BufferedStream(data: ""${'"'}
            blobby blob blob
            ""${'"'}.data(using: .utf8)!, isClosed: true)),
            host: "",
            resolvedHost: ""
        )

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")

        let input = StreamingTraitsInput(
            blob: .stream(BufferedStream(data: "blobby blob blob".data(using: .utf8)!, isClosed: true)),
            foo: "Foo"
        )
        let encoder = ClientRuntime.JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .withMethod(value: .post)
                      .build()
        var operationStack = OperationStack<StreamingTraitsInput, StreamingTraitsOutput>(id: "RestJsonStreamingTraitsWithBlob")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<StreamingTraitsInput, StreamingTraitsOutput>(urlPrefix: urlPrefix))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<StreamingTraitsInput, StreamingTraitsOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<StreamingTraitsOutput> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.HeaderMiddleware<StreamingTraitsInput, StreamingTraitsOutput>())
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<StreamingTraitsInput, StreamingTraitsOutput>(contentType: "application/octet-stream"))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.BlobStreamBodyMiddleware<StreamingTraitsInput, StreamingTraitsOutput>(keyPath: \.blob))
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<StreamingTraitsOutput, StreamingTraitsOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, isXML: false, isJSON: true) { expectedData, actualData in
                    XCTAssertEqual(expectedData, actualData)
                }
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try await StreamingTraitsOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<StreamingTraitsOutput>(httpResponse: response, output: mockOutput)
            return output
        })
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
            let serviceError = try await StreamingTraitsOutputError.makeError(httpResponse: httpResponse, decoder: decoder)
            throw serviceError
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
        var operationStack = OperationStack<HttpPrefixHeadersInput, HttpPrefixHeadersOutput>(id: "RestJsonHttpPrefixHeadersAreNotPresent")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<HttpPrefixHeadersInput, HttpPrefixHeadersOutput>(urlPrefix: urlPrefix))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<HttpPrefixHeadersInput, HttpPrefixHeadersOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<HttpPrefixHeadersOutput> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.HeaderMiddleware<HttpPrefixHeadersInput, HttpPrefixHeadersOutput>())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<HttpPrefixHeadersOutput, HttpPrefixHeadersOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            try await self.assertEqual(expected, actual)
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try await HttpPrefixHeadersOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<HttpPrefixHeadersOutput>(httpResponse: response, output: mockOutput)
            return output
        })
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
            let serviceError = try await HttpPrefixHeadersOutputError.makeError(httpResponse: httpResponse, decoder: decoder)
            throw serviceError
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
            body: .data( ""${'"'}
            {
                "contents": {
                    "stringValue": "foo"
                }
            }
            ""${'"'}.data(using: .utf8)!),
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
        var operationStack = OperationStack<JsonUnionsInput, JsonUnionsOutput>(id: "RestJsonSerializeStringUnionValue")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<JsonUnionsInput, JsonUnionsOutput>(urlPrefix: urlPrefix))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<JsonUnionsInput, JsonUnionsOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<JsonUnionsOutput> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<JsonUnionsInput, JsonUnionsOutput>(contentType: "application/json"))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.BodyMiddleware<JsonUnionsInput, JsonUnionsOutput, ClientRuntime.JSONWriter>(documentWritingClosure: ClientRuntime.JSONReadWrite.documentWritingClosure(encoder: encoder), inputWritingClosure: JSONReadWrite.writingClosure()))
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<JsonUnionsOutput, JsonUnionsOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, isXML: false, isJSON: true) { expectedData, actualData in
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
            let mockOutput = try await JsonUnionsOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<JsonUnionsOutput>(httpResponse: response, output: mockOutput)
            return output
        })
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
            let serviceError = try await JsonUnionsOutputError.makeError(httpResponse: httpResponse, decoder: decoder)
            throw serviceError
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
            body: .data( ""${'"'}
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
            ""${'"'}.data(using: .utf8)!),
            host: "",
            resolvedHost: ""
        )

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")

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
        let encoder = ClientRuntime.JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .withMethod(value: .put)
                      .build()
        var operationStack = OperationStack<RecursiveShapesInput, RecursiveShapesOutput>(id: "RestJsonRecursiveShapes")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<RecursiveShapesInput, RecursiveShapesOutput>(urlPrefix: urlPrefix))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<RecursiveShapesInput, RecursiveShapesOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<RecursiveShapesOutput> in
            input.withMethod(context.getMethod())
            input.withPath(context.getPath())
            let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<RecursiveShapesInput, RecursiveShapesOutput>(contentType: "application/json"))
        operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.BodyMiddleware<RecursiveShapesInput, RecursiveShapesOutput, ClientRuntime.JSONWriter>(documentWritingClosure: ClientRuntime.JSONReadWrite.documentWritingClosure(encoder: encoder), inputWritingClosure: JSONReadWrite.writingClosure()))
        operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<RecursiveShapesOutput, RecursiveShapesOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, isXML: false, isJSON: true) { expectedData, actualData in
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
            let mockOutput = try await RecursiveShapesOutput(httpResponse: response, decoder: nil)
            let output = OperationOutput<RecursiveShapesOutput>(httpResponse: response, output: mockOutput)
            return output
        })
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
            let serviceError = try await RecursiveShapesOutputError.makeError(httpResponse: httpResponse, decoder: decoder)
            throw serviceError
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
            body: .data( ""${'"'}
            {
                "stringValue": "string",
                "documentValue": {
                    "foo": "bar"
                }
            }
            ""${'"'}.data(using: .utf8)!),
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
            var operationStack = OperationStack<InlineDocumentInput, InlineDocumentOutput>(id: "InlineDocumentInput")
            operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<InlineDocumentInput, InlineDocumentOutput>(urlPrefix: urlPrefix))
            operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<InlineDocumentInput, InlineDocumentOutput>(host: hostOnly))
            operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<InlineDocumentOutput> in
                input.withMethod(context.getMethod())
                input.withPath(context.getPath())
                let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
                input.withHost(host)
                return try await next.handle(context: context, input: input)
            }
            operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<InlineDocumentInput, InlineDocumentOutput>(contentType: "application/json"))
            operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.BodyMiddleware<InlineDocumentInput, InlineDocumentOutput, ClientRuntime.JSONWriter>(documentWritingClosure: ClientRuntime.JSONReadWrite.documentWritingClosure(encoder: encoder), inputWritingClosure: JSONReadWrite.writingClosure()))
            operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
            operationStack.deserializeStep.intercept(position: .after,
                         middleware: MockDeserializeMiddleware<InlineDocumentOutput, InlineDocumentOutputError>(
                                 id: "TestDeserializeMiddleware"){ context, actual in
                try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                    XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                    XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                    try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, isXML: false, isJSON: true) { expectedData, actualData in
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
                let mockOutput = try await InlineDocumentOutput(httpResponse: response, decoder: nil)
                let output = OperationOutput<InlineDocumentOutput>(httpResponse: response, output: mockOutput)
                return output
            })
            _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
                XCTFail("Deserialize was mocked out, this should fail")
                let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
                let serviceError = try await InlineDocumentOutputError.makeError(httpResponse: httpResponse, decoder: decoder)
                throw serviceError
            })
        }
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
            body: .data( ""${'"'}
            {
                "foo": "bar"
            }
            ""${'"'}.data(using: .utf8)!),
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
            var operationStack = OperationStack<InlineDocumentAsPayloadInput, InlineDocumentAsPayloadOutput>(id: "InlineDocumentAsPayloadInput")
            operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<InlineDocumentAsPayloadInput, InlineDocumentAsPayloadOutput>(urlPrefix: urlPrefix))
            operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<InlineDocumentAsPayloadInput, InlineDocumentAsPayloadOutput>(host: hostOnly))
            operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<InlineDocumentAsPayloadOutput> in
                input.withMethod(context.getMethod())
                input.withPath(context.getPath())
                let host = "\(context.getHostPrefix() ?? "")\(context.getHost() ?? "")"
                input.withHost(host)
                return try await next.handle(context: context, input: input)
            }
            operationStack.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<InlineDocumentAsPayloadInput, InlineDocumentAsPayloadOutput>(contentType: "application/json"))
            operationStack.serializeStep.intercept(position: .after, middleware: ClientRuntime.PayloadBodyMiddleware<InlineDocumentAsPayloadInput, InlineDocumentAsPayloadOutput, ClientRuntime.Document, ClientRuntime.JSONWriter>(documentWritingClosure: ClientRuntime.JSONReadWrite.documentWritingClosure(encoder: encoder), inputWritingClosure: JSONReadWrite.writingClosure(), keyPath: \.documentValue, defaultBody: "{}"))
            operationStack.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
            operationStack.deserializeStep.intercept(position: .after,
                         middleware: MockDeserializeMiddleware<InlineDocumentAsPayloadOutput, InlineDocumentAsPayloadOutputError>(
                                 id: "TestDeserializeMiddleware"){ context, actual in
                try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                    XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                    XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                    try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, isXML: false, isJSON: true) { expectedData, actualData in
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
                let mockOutput = try await InlineDocumentAsPayloadOutput(httpResponse: response, decoder: nil)
                let output = OperationOutput<InlineDocumentAsPayloadOutput>(httpResponse: response, output: mockOutput)
                return output
            })
            _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
                XCTFail("Deserialize was mocked out, this should fail")
                let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
                let serviceError = try await InlineDocumentAsPayloadOutputError.makeError(httpResponse: httpResponse, decoder: decoder)
                throw serviceError
            })
        }
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
