/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import mocks.MockHTTPAWSJson11ProtocolGenerator
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.integration.HTTPBindingProtocolGenerator

class EventStreamsInitialResponseTests {
    @Test
    fun `should attempt to decode response if initial-response members are present in RPC (awsJson) smithy model`() {
        val context = setupInitialMessageTests(
            "event-stream-initial-request-response.smithy",
            "com.test#Example",
            MockHTTPAWSJson11ProtocolGenerator()
        )
        val contents = getFileContents(
            context.manifest,
            "/InitialMessageEventStreams/models/TestStreamOperationWithInitialRequestResponseOutput+HttpResponseBinding.swift"
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    static func httpOutput(from httpResponse: ClientRuntime.HttpResponse) async throws -> TestStreamOperationWithInitialRequestResponseOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyJSON.Reader.from(data: data)
        let reader = responseReader
        var value = TestStreamOperationWithInitialRequestResponseOutput()
        if case let .stream(stream) = httpResponse.body {
            let messageDecoder = ClientRuntime.MessageDecoder()
            let decoderStream = ClientRuntime.EventStream.DefaultMessageDecoderStream<InitialMessageEventStreamsClientTypes.TestStream>(stream: stream, messageDecoder: messageDecoder, unmarshalClosure: InitialMessageEventStreamsClientTypes.TestStream.unmarshal)
            value.value = decoderStream.toAsyncStream()
            if let initialDataWithoutHttp = await messageDecoder.awaitInitialResponse() {
                let decoder = JSONDecoder()
                do {
                    let response = try decoder.decode([String: String].self, from: initialDataWithoutHttp)
                    self.initial1 = response["initial1"]
                    self.initial2 = response["initial2"]
                } catch {
                    print("Error decoding JSON: \(error)")
                    self.initial1 = nil
                    self.initial2 = nil
                }
            } else {
                self.initial1 = nil
                self.initial2 = nil
            }
        } else {
            value.value = nil
        }
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupInitialMessageTests(
        smithyFile: String,
        serviceShapeId: String,
        protocolGenerator: HTTPBindingProtocolGenerator
    ): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, protocolGenerator) { model ->
            model.defaultSettings(serviceShapeId, "InitialMessageEventStreams", "123", "InitialMessageEventStreams")
        }
        context.generator.initializeMiddleware(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateProtocolClient(context.generationCtx)
        context.generator.generateDeserializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
