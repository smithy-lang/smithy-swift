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
        val contents = getFileContents(context.manifest, "/RestJsonTests/HttpRequestWithFloatLabelsRequestTest.swift")

        val expectedContents = """
class HttpRequestWithFloatLabelsRequestTest: HttpRequestTestBase {
    let host = "my-api.us-east-2.amazonaws.com"
    /// Supports handling NaN float label values.
    func testRestJsonSupportsNaNFloatLabels() throws {
        let expected = buildExpectedHttpRequest(
            method: .get,
            path: "/FloatHttpLabels/NaN/NaN",
            headers: [String: String](),
            body: nil,
            host: host
        )

        let deserializeMiddleware = expectation(description: "deserializeMiddleware")

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")

        let input = HttpRequestWithFloatLabelsInput(
            double: Swift.Double.nan,
            float: Swift.Float.nan
        )
        """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it can handle infinity values`() {
        val context = setupTests("Isolated/number-type-test.smithy", "aws.protocoltests.restjson#RestJson")
        val contents = getFileContents(context.manifest, "/RestJsonTests/HttpRequestWithFloatLabelsRequestTest.swift")

        val expectedContents =
            """
    func testRestJsonSupportsInfinityFloatLabels() throws {
            let expected = buildExpectedHttpRequest(
                method: .get,
                path: "/FloatHttpLabels/Infinity/Infinity",
                headers: [String: String](),
                body: nil,
                host: host
            )

            let deserializeMiddleware = expectation(description: "deserializeMiddleware")

            let decoder = ClientRuntime.JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")

            let input = HttpRequestWithFloatLabelsInput(
                double: Swift.Double.infinity,
                float: Swift.Float.infinity
            )
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it can handle negative infinity values`() {
        val context = setupTests("Isolated/number-type-test.smithy", "aws.protocoltests.restjson#RestJson")
        val contents = getFileContents(context.manifest, "/RestJsonTests/HttpRequestWithFloatLabelsRequestTest.swift")

        val expectedContents =
            """
    func testRestJsonSupportsNegativeInfinityFloatLabels() throws {
            let expected = buildExpectedHttpRequest(
                method: .get,
                path: "/FloatHttpLabels/-Infinity/-Infinity",
                headers: [String: String](),
                body: nil,
                host: host
            )
    
            let deserializeMiddleware = expectation(description: "deserializeMiddleware")
    
            let decoder = ClientRuntime.JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
    
            let input = HttpRequestWithFloatLabelsInput(
                double: -Swift.Double.infinity,
                float: -Swift.Float.infinity
            )
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it can handle nan values in response`() {
        val context = setupTests("Isolated/number-type-test.smithy", "aws.protocoltests.restjson#RestJson")
        val contents = getFileContents(context.manifest, "/RestJsonTests/InputAndOutputWithHeadersResponseTest.swift")

        val expectedContents =
            """
class InputAndOutputWithHeadersResponseTest: HttpResponseTestBase {
    let host = "my-api.us-east-2.amazonaws.com"
    /// Supports handling NaN float header values.
    func testRestJsonSupportsNaNFloatHeaderOutputs() throws {
        guard let httpResponse = buildHttpResponse(
            code: 200,
            headers: [
                "X-Double": "NaN",
                "X-Float": "NaN"
            ],
            host: host
        ) else {
            XCTFail("Something is wrong with the created http response")
            return
        }

        let actual = try InputAndOutputWithHeadersOutputResponse(httpResponse: httpResponse)

        let expected = InputAndOutputWithHeadersOutputResponse(
            headerDouble: Swift.Double.nan,
            headerFloat: Swift.Float.nan
        )

        XCTAssertEqual(expected.headerFloat?.isNaN, actual.headerFloat?.isNaN)
        XCTAssertEqual(expected.headerDouble?.isNaN, actual.headerDouble?.isNaN)

    }
}
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it generates the document type correctly`() {
        val context = setupTests("Isolated/document-type-test.smithy", "aws.protocoltests.restjson#RestJson")
        val contents = getFileContents(context.manifest, "/RestJsonTests/DocumentTypeRequestTest.swift")

        val expectedContents = """
class DocumentTypeRequestTest: HttpRequestTestBase {
    let host = "my-api.us-east-2.amazonaws.com"
    /// Serializes document types using a list.
    func testDocumentInputWithList() throws {
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/DocumentType",
            headers: [
                "Content-Type": "application/json"
            ],
            body: ""${'"'}
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
            ""${'"'},
            host: host
        )

        let deserializeMiddleware = expectation(description: "deserializeMiddleware")

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")

        let input = DocumentTypeInput(
            documentValue: try decoder.decode(Document.self, from:
                ""${'"'}
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
                ""${'"'}.data(using: .utf8)!)
                ,
                stringValue: "string"
            )
        """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestJsonProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestJson", "2019-12-16", "Rest Json Protocol")
        }
        context.generator.generateProtocolUnitTests(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
