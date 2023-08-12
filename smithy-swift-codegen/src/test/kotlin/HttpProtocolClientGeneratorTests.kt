/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class HttpProtocolClientGeneratorTests {

    @Test
    fun `it renders client initialization block`() {
        val context = setupTests("service-generator-test-operations.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/RestJson/RestJsonProtocolClient.swift")
        contents.shouldSyntacticSanityCheck()
        contents.shouldContainOnlyOnce(
            """
            public class RestJsonProtocolClient {
                public static let clientName = "RestJsonProtocolClient"
                let client: ClientRuntime.SdkHttpClient
                let config: RestJsonProtocol.RestJsonProtocolConfiguration
                let serviceName = "Rest Json Protocol"
                let encoder: ClientRuntime.RequestEncoder
                let decoder: ClientRuntime.ResponseDecoder
            
                public init(config: RestJsonProtocol.RestJsonProtocolConfiguration) {
                    client = ClientRuntime.SdkHttpClient(engine: config.httpClientEngine, config: config.httpClientConfiguration)
                    let encoder = ClientRuntime.JSONEncoder()
                    encoder.dateEncodingStrategy = .secondsSince1970
                    encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
                    self.encoder = config.encoder ?? encoder
                    let decoder = ClientRuntime.JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
                    self.decoder = config.decoder ?? decoder
                    self.config = config
                }
            
                public convenience init() throws {
                    let config = try RestJsonProtocol.RestJsonProtocolConfiguration()
                    self.init(config: config)
                }
            }
            
            public init(runtimeConfig: ClientRuntime.DefaultSDKRuntimeConfiguration) throws {
                self.clientLogMode = runtimeConfig.clientLogMode
                self.decoder = runtimeConfig.decoder
                self.encoder = runtimeConfig.encoder
                self.httpClientConfiguration = runtimeConfig.httpClientConfiguration
                self.httpClientEngine = runtimeConfig.httpClientEngine
                self.idempotencyTokenGenerator = runtimeConfig.idempotencyTokenGenerator
                self.logger = runtimeConfig.logger
                self.retryStrategyOptions = runtimeConfig.retryStrategyOptions
            }
            
            public convenience init() throws {
                let defaultRuntimeConfig = try ClientRuntime.DefaultSDKRuntimeConfiguration("Rest Json Protocol")
                try self.init(runtimeConfig: defaultRuntimeConfig)
            }
            
            public struct RestJsonProtocolClientLogHandlerFactory: ClientRuntime.SDKLogHandlerFactory {
                public var label = "RestJsonProtocolClient"
                let logLevel: ClientRuntime.SDKLogLevel
                public func construct(label: String) -> LogHandler {
                    var handler = StreamLogHandler.standardOutput(label: label)
                    handler.logLevel = logLevel.toLoggerType()
                    return handler
                }
                public init(logLevel: ClientRuntime.SDKLogLevel) {
                    self.logLevel = logLevel
                }
            }
            """.trimIndent()
        )
    }

    @Test
    fun `it renders host prefix with label in context correctly`() {
        val context = setupTests("host-prefix-operation.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/RestJson/RestJsonProtocolClient.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedFragment = """
        let context = ClientRuntime.HttpContextBuilder()
                      .withEncoder(value: encoder)
                      .withDecoder(value: decoder)
                      .withMethod(value: .post)
                      .withServiceName(value: serviceName)
                      .withOperation(value: "getStatus")
                      .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
                      .withLogger(value: config.logger)
        """
        contents.shouldContainOnlyOnce(expectedFragment)
    }

    @Test
    fun `it renders operation implementations in extension`() {
        val context = setupTests("service-generator-test-operations.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/RestJson/RestJsonProtocolClient.swift")
        contents.shouldSyntacticSanityCheck()
        contents.shouldContainOnlyOnce("extension RestJsonProtocolClient: RestJsonProtocolClientProtocol {")
    }

    @Test
    fun `it renders an operation body`() {
        val context = setupTests("service-generator-test-operations.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/RestJson/RestJsonProtocolClient.swift")
        contents.shouldSyntacticSanityCheck()
        val expected = """
        extension RestJsonProtocolClient: RestJsonProtocolClientProtocol {
            /// This is a very cool operation.
            ///
            /// - Parameter AllocateWidgetInput : [no documentation found]
            ///
            /// - Returns: `AllocateWidgetOutputResponse` : [no documentation found]
            ///
            /// - Throws: `AllocateWidgetError` : Wrapper object for possible exceptions listed below.
            ///
            /// __Possible Exceptions:__
            /// This operation throws no exceptions.
            public func allocateWidget(input: AllocateWidgetInput) async throws -> AllocateWidgetOutputResponse
            {
                let context = ClientRuntime.HttpContextBuilder()
                              .withEncoder(value: encoder)
                              .withDecoder(value: decoder)
                              .withMethod(value: .post)
                              .withServiceName(value: serviceName)
                              .withOperation(value: "allocateWidget")
                              .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
                              .withLogger(value: config.logger)
                              .withPartitionID(value: config.partitionID)
                              .build()
                var operation = ClientRuntime.OperationStack<AllocateWidgetInput, AllocateWidgetOutputResponse, AllocateWidgetOutputError>(id: "allocateWidget")
                operation.initializeStep.intercept(position: .after, id: "IdempotencyTokenMiddleware") { (context, input, next) -> ClientRuntime.OperationOutput<AllocateWidgetOutputResponse> in
                    let idempotencyTokenGenerator = context.getIdempotencyTokenGenerator()
                    var copiedInput = input
                    if input.clientToken == nil {
                        copiedInput.clientToken = idempotencyTokenGenerator.generateToken()
                    }
                    return try await next.handle(context: context, input: copiedInput)
                }
                operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<AllocateWidgetInput, AllocateWidgetOutputResponse, AllocateWidgetOutputError>())
                operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<AllocateWidgetInput, AllocateWidgetOutputResponse>())
                operation.serializeStep.intercept(position: .after, middleware: ContentTypeMiddleware<AllocateWidgetInput, AllocateWidgetOutputResponse>(contentType: "application/json"))
                operation.serializeStep.intercept(position: .after, middleware: ClientRuntime.SerializableBodyMiddleware<AllocateWidgetInput, AllocateWidgetOutputResponse>(xmlName: "AllocateWidgetInput"))
                operation.finalizeStep.intercept(position: .before, middleware: ClientRuntime.ContentLengthMiddleware())
                operation.finalizeStep.intercept(position: .after, middleware: ClientRuntime.RetryMiddleware<ClientRuntime.DefaultRetryStrategy, ClientRuntime.DefaultRetryErrorInfoProvider, AllocateWidgetOutputResponse, AllocateWidgetOutputError>(options: config.retryStrategyOptions))
                operation.deserializeStep.intercept(position: .after, middleware: ClientRuntime.DeserializeMiddleware<AllocateWidgetOutputResponse, AllocateWidgetOutputError>())
                operation.deserializeStep.intercept(position: .after, middleware: ClientRuntime.LoggerMiddleware<AllocateWidgetOutputResponse, AllocateWidgetOutputError>(clientLogMode: config.clientLogMode))
                let result = try await operation.handleMiddleware(context: context, input: input, next: client.getHandler())
                return result
            }
        """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestJsonProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestJson", "2019-12-16", "Rest Json Protocol")
        }
        context.generator.initializeMiddleware(context.generationCtx)
        context.generator.generateProtocolClient(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
