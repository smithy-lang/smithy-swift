import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class IsolatedHttpProtocolUnitTestRequestGeneratorTests {
    @Test
    fun `it can handle nan values`() {
        val context = setupTests("Isolated/number-test.smithy", "aws.protocoltests.restjson#RestJson")
        val contents = getFileContents(context.manifest, "/RestJsonTests/HttpRequestWithFloatLabelsRequestTest.swift")

        val expectedContents = """
    func testRestJsonSupportsNaNFloatLabels() {
        let expected = buildExpectedHttpRequest(
            method: .get,
            path: "/FloatHttpLabels/NaN/NaN",
            headers: [String: String](),
            queryParams: [String](),
            body: nil,
            host: host
        )

        let deserializeMiddleware = expectation(description: "deserializeMiddleware")

        let input = HttpRequestWithFloatLabelsInput(
            double: Double.nan,
            float: Float.nan
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let context = HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .build()
        var operationStack = OperationStack<HttpRequestWithFloatLabelsInput, HttpRequestWithFloatLabelsOutputResponse, HttpRequestWithFloatLabelsOutputError>(id: "RestJsonSupportsNaNFloatLabels")
        operationStack.serializeStep.intercept(position: .before, middleware: HttpRequestWithFloatLabelsInputHeadersMiddleware())
        operationStack.serializeStep.intercept(position: .before, middleware: HttpRequestWithFloatLabelsInputQueryItemMiddleware())
        operationStack.deserializeStep.intercept(position: .after,
                     middleware: MockDeserializeMiddleware<HttpRequestWithFloatLabelsOutputResponse, HttpRequestWithFloatLabelsOutputError>(
                             id: "TestDeserializeMiddleware"){ context, actual in
            self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssert(actualHttpBody == HttpBody.none, "The actual HttpBody is not none as expected")
                XCTAssert(expectedHttpBody == HttpBody.none, "The expected HttpBody is not none as expected")
            })
            let response = HttpResponse(body: HttpBody.none, statusCode: .ok)
            let mockOutput = try! HttpRequestWithFloatLabelsOutputResponse(httpResponse: response, decoder: nil)
            let output = OperationOutput<HttpRequestWithFloatLabelsOutputResponse>(httpResponse: response, output: mockOutput)
            deserializeMiddleware.fulfill()
            return .success(output)
        })
        _ = operationStack.handleMiddleware(context: context, input: input, next: MockHandler(){ (context, request) in
            XCTFail("Deserialize was mocked out, this should fail")
            let httpResponse = HttpResponse(body: .none, statusCode: .badRequest)
            let serviceError = try! HttpRequestWithFloatLabelsOutputError(httpResponse: httpResponse)
            return .failure(.service(serviceError, httpResponse))
        })
        wait(for: [deserializeMiddleware], timeout: 0.3)
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