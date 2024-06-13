/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class IsolatedHttpProtocolUnitTestRequestGeneratorTests {
    @Test
    fun `it can handle nan values`() {
        val context = setupTests("Isolated/number-type-test.smithy", "aws.protocoltests.restjson#RestJson")
        val contents = getFileContents(context.manifest, "Tests/RestJsonTests/HttpRequestWithFloatLabelsRequestTest.swift")

        val expectedContents = """
    func testRestJsonSupportsNaNFloatLabels() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .get,
            path: "/FloatHttpLabels/NaN/NaN",
            body: nil,
            host: "",
            resolvedHost: ""
        )

        let input = HttpRequestWithFloatLabelsInput(
            double: Swift.Double.nan,
            float: Swift.Float.nan
        )
        let context = ContextBuilder()
                      .withMethod(value: .get)
                      .build()
        var operationStack = OperationStack<HttpRequestWithFloatLabelsInput, HttpRequestWithFloatLabelsOutput>(id: "RestJsonSupportsNaNFloatLabels")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<HttpRequestWithFloatLabelsInput, HttpRequestWithFloatLabelsOutput>(urlPrefix: urlPrefix, HttpRequestWithFloatLabelsInput.urlPathProvider(_:)))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<HttpRequestWithFloatLabelsInput, HttpRequestWithFloatLabelsOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<HttpRequestWithFloatLabelsOutput> in
            input.withMethod(context.method)
            input.withPath(context.path)
            let host = "\(context.hostPrefix ?? "")\(context.host ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.deserializeStep.intercept(
            position: .after,
            middleware: MockDeserializeMiddleware<HttpRequestWithFloatLabelsOutput>(
                id: "TestDeserializeMiddleware",
                responseClosure: HttpRequestWithFloatLabelsOutput.httpOutput(from:),
                callback: { context, actual in
                    try await self.assertEqual(expected, actual)
                    return OperationOutput(httpResponse: HttpResponse(body: ByteStream.noStream, statusCode: .ok), output: HttpRequestWithFloatLabelsOutput())
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
    fun `it can handle infinity values`() {
        val context = setupTests("Isolated/number-type-test.smithy", "aws.protocoltests.restjson#RestJson")
        val contents = getFileContents(context.manifest, "Tests/RestJsonTests/HttpRequestWithFloatLabelsRequestTest.swift")

        val expectedContents = """
    func testRestJsonSupportsInfinityFloatLabels() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .get,
            path: "/FloatHttpLabels/Infinity/Infinity",
            body: nil,
            host: "",
            resolvedHost: ""
        )

        let input = HttpRequestWithFloatLabelsInput(
            double: Swift.Double.infinity,
            float: Swift.Float.infinity
        )
        let context = ContextBuilder()
                      .withMethod(value: .get)
                      .build()
        var operationStack = OperationStack<HttpRequestWithFloatLabelsInput, HttpRequestWithFloatLabelsOutput>(id: "RestJsonSupportsInfinityFloatLabels")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<HttpRequestWithFloatLabelsInput, HttpRequestWithFloatLabelsOutput>(urlPrefix: urlPrefix, HttpRequestWithFloatLabelsInput.urlPathProvider(_:)))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<HttpRequestWithFloatLabelsInput, HttpRequestWithFloatLabelsOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<HttpRequestWithFloatLabelsOutput> in
            input.withMethod(context.method)
            input.withPath(context.path)
            let host = "\(context.hostPrefix ?? "")\(context.host ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.deserializeStep.intercept(
            position: .after,
            middleware: MockDeserializeMiddleware<HttpRequestWithFloatLabelsOutput>(
                id: "TestDeserializeMiddleware",
                responseClosure: HttpRequestWithFloatLabelsOutput.httpOutput(from:),
                callback: { context, actual in
                    try await self.assertEqual(expected, actual)
                    return OperationOutput(httpResponse: HttpResponse(body: ByteStream.noStream, statusCode: .ok), output: HttpRequestWithFloatLabelsOutput())
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
    fun `it can handle negative infinity values`() {
        val context = setupTests("Isolated/number-type-test.smithy", "aws.protocoltests.restjson#RestJson")
        val contents = getFileContents(context.manifest, "Tests/RestJsonTests/HttpRequestWithFloatLabelsRequestTest.swift")

        val expectedContents = """
    func testRestJsonSupportsNegativeInfinityFloatLabels() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .get,
            path: "/FloatHttpLabels/-Infinity/-Infinity",
            body: nil,
            host: "",
            resolvedHost: ""
        )

        let input = HttpRequestWithFloatLabelsInput(
            double: -Swift.Double.infinity,
            float: -Swift.Float.infinity
        )
        let context = ContextBuilder()
                      .withMethod(value: .get)
                      .build()
        var operationStack = OperationStack<HttpRequestWithFloatLabelsInput, HttpRequestWithFloatLabelsOutput>(id: "RestJsonSupportsNegativeInfinityFloatLabels")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<HttpRequestWithFloatLabelsInput, HttpRequestWithFloatLabelsOutput>(urlPrefix: urlPrefix, HttpRequestWithFloatLabelsInput.urlPathProvider(_:)))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<HttpRequestWithFloatLabelsInput, HttpRequestWithFloatLabelsOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<HttpRequestWithFloatLabelsOutput> in
            input.withMethod(context.method)
            input.withPath(context.path)
            let host = "\(context.hostPrefix ?? "")\(context.host ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.deserializeStep.intercept(
            position: .after,
            middleware: MockDeserializeMiddleware<HttpRequestWithFloatLabelsOutput>(
                id: "TestDeserializeMiddleware",
                responseClosure: HttpRequestWithFloatLabelsOutput.httpOutput(from:),
                callback: { context, actual in
                    try await self.assertEqual(expected, actual)
                    return OperationOutput(httpResponse: HttpResponse(body: ByteStream.noStream, statusCode: .ok), output: HttpRequestWithFloatLabelsOutput())
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
    fun `it can handle nan values in response`() {
        val context = setupTests("Isolated/number-type-test.smithy", "aws.protocoltests.restjson#RestJson")
        val contents = getFileContents(context.manifest, "Tests/RestJsonTests/InputAndOutputWithHeadersResponseTest.swift")

        val expectedContents = """
class InputAndOutputWithHeadersResponseTest: HttpResponseTestBase {
    /// Supports handling NaN float header values.
    func testRestJsonSupportsNaNFloatHeaderOutputs() async throws {
        guard let httpResponse = buildHttpResponse(
            code: 200,
            headers: [
                "X-Double": "NaN",
                "X-Float": "NaN"
            ],
            content: nil
        ) else {
            XCTFail("Something is wrong with the created http response")
            return
        }

        let actual: InputAndOutputWithHeadersOutput = try await InputAndOutputWithHeadersOutput.httpOutput(from:)(httpResponse)

        let expected = InputAndOutputWithHeadersOutput(
            headerDouble: Swift.Double.nan,
            headerFloat: Swift.Float.nan
        )

        XCTAssertEqual(actual, expected)

    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it generates the document type correctly`() {
        val context = setupTests("Isolated/document-type-test.smithy", "aws.protocoltests.restjson#RestJson")
        val contents = getFileContents(context.manifest, "Tests/RestJsonTests/DocumentTypeRequestTest.swift")

        val expectedContents = """
class DocumentTypeRequestTest: HttpRequestTestBase {
    /// Serializes document types using a list.
    func testDocumentInputWithList() async throws {
        let urlPrefix = urlPrefixFromHost(host: "")
        let hostOnly = hostOnlyFromHost(host: "")
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/DocumentType",
            headers: [
                "Content-Type": "application/json"
            ],
            body: .data(Data(""${'"'}
            {
                "stringValue": "string",
                "documentValue": [
                    true,
                    "hi",
                    [
                        1,
                        2
                    ],
                    {
                        "foo": {
                            "baz": [
                                3,
                                4
                            ]
                        }
                    }
                ]
            }
            ""${'"'}.utf8)),
            host: "",
            resolvedHost: ""
        )

        let input = DocumentTypeInput(
            documentValue: try SmithyReadWrite.Document.make(from: Data(""${'"'}
                [
                    true,
                    "hi",
                    [
                        1,
                        2
                    ],
                    {
                        "foo": {
                            "baz": [
                                3,
                                4
                            ]
                        }
                    }
                ]
            ""${'"'}.utf8))
            ,
            stringValue: "string"
        )
        let context = ContextBuilder()
                      .withMethod(value: .put)
                      .build()
        var operationStack = OperationStack<DocumentTypeInput, DocumentTypeOutput>(id: "DocumentInputWithList")
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<DocumentTypeInput, DocumentTypeOutput>(urlPrefix: urlPrefix, DocumentTypeInput.urlPathProvider(_:)))
        operationStack.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<DocumentTypeInput, DocumentTypeOutput>(host: hostOnly))
        operationStack.buildStep.intercept(position: .after, id: "RequestTestEndpointResolver") { (context, input, next) -> ClientRuntime.OperationOutput<DocumentTypeOutput> in
            input.withMethod(context.method)
            input.withPath(context.path)
            let host = "\(context.hostPrefix ?? "")\(context.host ?? "")"
            input.withHost(host)
            return try await next.handle(context: context, input: input)
        }
        operationStack.deserializeStep.intercept(
            position: .after,
            middleware: MockDeserializeMiddleware<DocumentTypeOutput>(
                id: "TestDeserializeMiddleware",
                responseClosure: DocumentTypeOutput.httpOutput(from:),
                callback: { context, actual in
                    try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                        XCTAssertNotNil(actualHttpBody, "The actual ByteStream is nil")
                        XCTAssertNotNil(expectedHttpBody, "The expected ByteStream is nil")
                        try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, contentType: .json)
                    })
                    return OperationOutput(httpResponse: HttpResponse(body: ByteStream.noStream, statusCode: .ok), output: DocumentTypeOutput())
                }
            )
        )
        _ = try await operationStack.handleMiddleware(context: context, input: input, next: MockHandler() { (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            throw SmithyTestUtilError("Mock handler unexpectedly failed")
        })
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHTTPRestJsonProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestJson", "2019-12-16", "Rest Json Protocol")
        }
        context.generator.generateProtocolUnitTests(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
