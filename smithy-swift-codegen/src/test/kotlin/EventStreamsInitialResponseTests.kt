/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import mocks.MockHttpAWSJson11ProtocolGenerator
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.integration.HttpBindingProtocolGenerator

class EventStreamsInitialResponseTests {
    @Test
    fun `should attempt to decode response if initial-response members are present in RPC (awsJson) smithy model`() {
        val context = setupInitialMessageTests(
            "event-stream-initial-request-response.smithy",
            "com.test#Example",
            MockHttpAWSJson11ProtocolGenerator()
        )
        val contents = getFileContents(
            context.manifest,
            "/InitialMessageEventStreams/models/TestStreamOperationWithInitialRequestResponseOutput+HttpResponseBinding.swift"
        )
        contents.shouldSyntacticSanityCheck()
        contents.shouldContainOnlyOnce(
            """
            extension TestStreamOperationWithInitialRequestResponseOutput: ClientRuntime.HttpResponseBinding {
                public init(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder? = nil) async throws {
                    if case let .stream(stream) = await httpResponse.body, let responseDecoder = decoder {
                        let messageDecoder: ClientRuntime.MessageDecoder? = nil
                        let decoderStream = ClientRuntime.EventStream.DefaultMessageDecoderStream<InitialMessageEventStreamsClientTypes.TestStream>(stream: stream, messageDecoder: messageDecoder, responseDecoder: responseDecoder)
                        self.value = decoderStream.toAsyncStream()
                        if let initialDataWithoutHttp = await messageDecoder.awaitInitialResponse() {
                            let decoder = JSONDecoder()
                            do {
                                let response = try decoder.decode([String: String].self, from: initialDataWithoutHttp)
                                self.initial1 = response["initial1"].map { value in KinesisClientTypes.Tag(value: value) }
                                self.initial2 = response["initial2"].map { value in KinesisClientTypes.Tag(value: value) }
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
                        self.value = nil
                    }
                }
            }
            """.trimIndent()
        )
    }

    private fun setupInitialMessageTests(
        smithyFile: String,
        serviceShapeId: String,
        protocolGenerator: HttpBindingProtocolGenerator
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
