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
            queryParams: [String](),
            body: nil,
            host: host
        )

        let deserializeMiddleware = expectation(description: "deserializeMiddleware")

        let decoder = JSONDecoder()

        let input = HttpRequestWithFloatLabelsInput(
            double: Double.nan,
            float: Float.nan
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
                queryParams: [String](),
                body: nil,
                host: host
            )

            let deserializeMiddleware = expectation(description: "deserializeMiddleware")

            let decoder = JSONDecoder()

            let input = HttpRequestWithFloatLabelsInput(
                double: Double.infinity,
                float: Float.infinity
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
            queryParams: [String](),
            body: nil,
            host: host
        )
        
        let deserializeMiddleware = expectation(description: "deserializeMiddleware")

        let decoder = JSONDecoder()

        let input = HttpRequestWithFloatLabelsInput(
            double: -Double.infinity,
            float: -Float.infinity
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
            headerDouble: Double.nan,
            headerFloat: Float.nan
        )

        XCTAssertEqual(expected.headerFloat?.isNaN && actual.headerFloat?.isNaN)
        XCTAssertEqual(expected.headerDouble?.isNaN && actual.headerDouble?.isNaN)

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
            queryParams: [String](),
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

        let decoder = JSONDecoder()

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
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            let context = HttpContextBuilder()
                          .withEncoder(value: encoder)
                          .build()
            var operationStack = OperationStack<DocumentTypeInput, DocumentTypeOutputResponse, DocumentTypeOutputError>(id: "DocumentInputWithList")
            operationStack.serializeStep.intercept(position: .before, middleware: DocumentTypeInputHeadersMiddleware())
            operationStack.serializeStep.intercept(position: .before, middleware: DocumentTypeInputQueryItemMiddleware())
            operationStack.serializeStep.intercept(position: .before, middleware: DocumentTypeInputBodyMiddleware())
            operationStack.serializeStep.intercept(position: .before, middleware: ContentTypeMiddleware<DocumentTypeInput, DocumentTypeOutputResponse, DocumentTypeOutputError>(contentType: "application/json"))
            operationStack.buildStep.intercept(position: .before, middleware: ContentLengthMiddleware<DocumentTypeOutputResponse, DocumentTypeOutputError>())
            operationStack.deserializeStep.intercept(position: .after,
                         middleware: MockDeserializeMiddleware<DocumentTypeOutputResponse, DocumentTypeOutputError>(
                                 id: "TestDeserializeMiddleware"){ context, actual in
                self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                    XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                    XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                    self.genericAssertEqualHttpBodyData(expectedHttpBody!, actualHttpBody!) { expectedData, actualData in
                        do {
                            let expectedObj = try decoder.decode(DocumentTypeInputBody.self, from: expectedData)
                            let actualObj = try decoder.decode(DocumentTypeInputBody.self, from: actualData)
                            XCTAssertEqual(expectedObj, actualObj)
                        } catch let err {
                            XCTFail("Failed to verify body \(err)")
                        }
                    }
                })
                let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
                let mockOutput = try! DocumentTypeOutputResponse(httpResponse: response, decoder: nil)
                let output = OperationOutput<DocumentTypeOutputResponse>(httpResponse: response, output: mockOutput)
                deserializeMiddleware.fulfill()
                return .success(output)
            })
            _ = operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
                XCTFail("Deserialize was mocked out, this should fail")
                let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
                let serviceError = try! DocumentTypeOutputError(httpResponse: httpResponse)
                return .failure(.service(serviceError, httpResponse))
            })
            wait(for: [deserializeMiddleware], timeout: 0.3)
        }
    }
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
