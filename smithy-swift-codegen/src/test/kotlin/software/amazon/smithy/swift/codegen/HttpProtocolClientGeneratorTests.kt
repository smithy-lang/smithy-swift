package software.amazon.smithy.swift.codegen

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.protocolgeneratormocks.MockHTTPRestJsonProtocolGenerator

class HttpProtocolClientGeneratorTests {
    @Test
    fun `it renders client initialization block`() {
        val context = setupTests("service-generator-test-operations.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/RestJson/RestJsonProtocolClient.swift")
        contents.shouldSyntacticSanityCheck()
        // Verify struct instead of class
        contents.shouldContain("public struct RestJsonProtocolClientConfiguration:")
        // Verify Sendable without @unchecked
        contents.shouldContain(", Sendable {")
        // Verify immutable properties (let instead of var)
        contents.shouldContain("public let telemetryProvider: ClientRuntime.TelemetryProvider")
        contents.shouldContain("public let httpClientEngine: SmithyHTTPAPI.HTTPClient")
        // Verify no private init (structs don't need it)
        contents.shouldContain("public init(")
    }

    @Test
    fun `it renders host prefix with label in context correctly`() {
        val context = setupTests("host-prefix-operation.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/RestJson/RestJsonProtocolClient.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedFragment = """
        let context = Smithy.ContextBuilder()
                      .withMethod(value: .post)
                      .withServiceName(value: serviceName)
                      .withOperation(value: "getStatus")
                      .withUnsignedPayloadTrait(value: false)
                      .withSmithyDefaultConfig(config)
                      .build()
"""
        contents.shouldContainOnlyOnce(expectedFragment)
    }

    @Test
    fun `it renders operation implementations in extension`() {
        val context = setupTests("service-generator-test-operations.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/RestJson/RestJsonProtocolClient.swift")
        contents.shouldSyntacticSanityCheck()
        contents.shouldContain("extension RestJsonProtocolClient {")
    }

    @Test
    fun `it renders an operation body`() {
        val context = setupTests("service-generator-test-operations.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/RestJson/RestJsonProtocolClient.swift")
        contents.shouldSyntacticSanityCheck()
        val expected = """
    public func allocateWidget(input: AllocateWidgetInput) async throws -> AllocateWidgetOutput {
        let context = Smithy.ContextBuilder()
                      .withMethod(value: .post)
                      .withServiceName(value: serviceName)
                      .withOperation(value: "allocateWidget")
                      .withUnsignedPayloadTrait(value: false)
                      .withSmithyDefaultConfig(config)
                      .build()
        let builder = ClientRuntime.OrchestratorBuilder<AllocateWidgetInput, AllocateWidgetOutput, SmithyHTTPAPI.HTTPRequest, SmithyHTTPAPI.HTTPResponse>()
        config.interceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        config.httpInterceptorProviders.forEach { provider in
            builder.interceptors.add(provider.create())
        }
        builder.interceptors.add(ClientRuntime.IdempotencyTokenMiddleware<AllocateWidgetInput, AllocateWidgetOutput>(keyPath: \.clientToken))
        builder.interceptors.add(ClientRuntime.URLPathMiddleware<AllocateWidgetInput, AllocateWidgetOutput>(AllocateWidgetInput.urlPathProvider(_:)))
        builder.interceptors.add(ClientRuntime.URLHostMiddleware<AllocateWidgetInput, AllocateWidgetOutput>())
        builder.interceptors.add(ClientRuntime.ContentTypeMiddleware<AllocateWidgetInput, AllocateWidgetOutput>(contentType: "application/json"))
        builder.serialize(ClientRuntime.BodyMiddleware<AllocateWidgetInput, AllocateWidgetOutput, SmithyJSON.Writer>(rootNodeInfo: "", inputWritingClosure: AllocateWidgetInput.write(value:to:)))
        builder.interceptors.add(ClientRuntime.ContentLengthMiddleware<AllocateWidgetInput, AllocateWidgetOutput>())
        builder.deserialize(ClientRuntime.DeserializeMiddleware<AllocateWidgetOutput>(AllocateWidgetOutput.httpOutput(from:), AllocateWidgetOutputError.httpError(from:)))
        builder.interceptors.add(ClientRuntime.LoggerMiddleware<AllocateWidgetInput, AllocateWidgetOutput>(clientLogMode: config.clientLogMode))
        builder.clockSkewProvider(ClientRuntime.DefaultClockSkewProvider.provider())
        builder.retryStrategy(SmithyRetries.DefaultRetryStrategy(options: config.retryStrategyOptions))
        builder.retryErrorInfoProvider(ClientRuntime.DefaultRetryErrorInfoProvider.errorInfo(for:))
        builder.applySigner(ClientRuntime.SignerMiddleware<AllocateWidgetOutput>())
        builder.selectAuthScheme(ClientRuntime.AuthSchemeMiddleware<AllocateWidgetOutput>())
        var metricsAttributes = Smithy.Attributes()
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.service, value: "RestJsonProtocol")
        metricsAttributes.set(key: ClientRuntime.OrchestratorMetricsAttributesKeys.method, value: "AllocateWidget")
        let op = builder.attributes(context)
            .telemetry(ClientRuntime.OrchestratorTelemetry(
                telemetryProvider: config.telemetryProvider,
                metricsAttributes: metricsAttributes,
                meterScope: serviceName,
                tracerScope: serviceName
            ))
            .executeRequest(client)
            .build()
        return try await op.execute(input: input)
    }
"""
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `ContentLengthMiddleware generates correctly with requiresLength false and unsignedPayload true`() {
        val context = setupTests("service-generator-test-operations.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/RestJson/RestJsonProtocolClient.swift")
        contents.shouldSyntacticSanityCheck()
        contents.shouldContainOnlyOnce(
            "builder.interceptors.add(ClientRuntime.ContentLengthMiddleware<UnsignedFooBlobStreamInput, UnsignedFooBlobStreamOutput>(requiresLength: false, unsignedPayload: true))",
        )
    }

    @Test
    fun `ContentLengthMiddleware generates correctly with requiresLength true and unsignedPayload false`() {
        val context = setupTests("service-generator-test-operations.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/RestJson/RestJsonProtocolClient.swift")
        contents.shouldSyntacticSanityCheck()
        contents.shouldContainOnlyOnce(
            "builder.interceptors.add(ClientRuntime.ContentLengthMiddleware<ExplicitBlobStreamWithLengthInput, ExplicitBlobStreamWithLengthOutput>(requiresLength: true, unsignedPayload: false))",
        )
    }

    @Test
    fun `ContentLengthMiddleware generates correctly with requiresLength true and unsignedPayload true`() {
        val context = setupTests("service-generator-test-operations.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/RestJson/RestJsonProtocolClient.swift")
        contents.shouldSyntacticSanityCheck()
        contents.shouldContainOnlyOnce(
            "builder.interceptors.add(ClientRuntime.ContentLengthMiddleware<UnsignedFooBlobStreamWithLengthInput, UnsignedFooBlobStreamWithLengthOutput>(requiresLength: true, unsignedPayload: true))",
        )
    }

    private fun setupTests(
        smithyFile: String,
        serviceShapeId: String,
    ): TestContext {
        val context =
            TestContext.initContextFrom(
                listOf(smithyFile),
                serviceShapeId,
                MockHTTPRestJsonProtocolGenerator(),
                { model -> model.defaultSettings(serviceShapeId, "RestJson", "2019-12-16", "Rest Json Protocol") },
                listOf(DefaultClientConfigurationIntegration()),
            )

        context.generator.initializeMiddleware(context.generationCtx)
        context.generator.generateProtocolClient(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
