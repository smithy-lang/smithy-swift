package serde.awsjson11

import TestContext
import asSmithy
import defaultSettings
import getModelFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import newTestContext
import org.junit.jupiter.api.Test
import shouldSyntacticSanityCheck
import software.amazon.smithy.swift.codegen.model.AddOperationShapes

// NOTE: protocol conformance is mostly handled by the protocol tests suite
class OutputDeserializerTests {
    private var model = javaClass.getResource("awsjson-output-response-deserializer.smithy").asSmithy()
    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        return model.newTestContext()
    }

    val newTestContext = newTestContext()

    init {
        newTestContext.generator.generateSerializers(newTestContext.generationCtx)
        newTestContext.generator.generateProtocolClient(newTestContext.generationCtx)
        newTestContext.generator.generateDeserializers(newTestContext.generationCtx)
        newTestContext.generator.generateCodableConformanceForNestedTypes(newTestContext.generationCtx)
        newTestContext.generationCtx.delegator.flushWriters()
    }

    @Test
    fun `it creates correct init for simple structure payloads`() {
        val contents = getModelFileContents(
            "example",
            "SimpleStructureOutput+HttpResponseBinding.swift",
            newTestContext.manifest
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension SimpleStructureOutput: ClientRuntime.HttpResponseBinding {
                public init(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder? = nil) async throws {
                    if let data = try await httpResponse.body.readData(),
                        let responseDecoder = decoder {
                        let output: SimpleStructureOutputBody = try responseDecoder.decode(responseBody: data)
                        self.name = output.name
                        self.number = output.number
                    } else {
                        self.name = nil
                        self.number = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates correct init for data streaming payloads`() {
        val contents = getModelFileContents(
            "example",
            "DataStreamingOutput+HttpResponseBinding.swift",
            newTestContext.manifest
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension DataStreamingOutput: ClientRuntime.HttpResponseBinding {
                public init(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder? = nil) async throws {
                    switch await httpResponse.body {
                    case .data(let data):
                        self.streamingData = .data(data)
                    case .stream(let stream):
                        self.streamingData = .stream(stream)
                    case .noStream:
                        self.streamingData = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates correct init for event streaming payloads`() {
        val contents = getModelFileContents(
            "example",
            "EventStreamingOutput+HttpResponseBinding.swift",
            newTestContext.manifest
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension EventStreamingOutput: ClientRuntime.HttpResponseBinding {
                public init(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder? = nil) async throws {
                    if case let .stream(stream) = await httpResponse.body, let responseDecoder = decoder {
                        let messageDecoder: ClientRuntime.MessageDecoder? = nil
                        let decoderStream = ClientRuntime.EventStream.DefaultMessageDecoderStream<EventStream>(stream: stream, messageDecoder: messageDecoder, responseDecoder: responseDecoder)
                        self.eventStream = decoderStream.toAsyncStream()
                    } else {
                        self.eventStream = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
