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
        val expected = """
public final class RestJsonProtocolClient: ClientRuntime.Client {
    public static let clientName = "RestJsonProtocolClient"
    public static let version = "2019-12-16"
    let client: ClientRuntime.SdkHttpClient
    public let config: RestJsonProtocolClient.RestJsonProtocolClientConfig
    let serviceName = "Rest Json Protocol"

    @available(*, deprecated, message: "Use RestJsonProtocolClient.RestJsonProtocolClientConfig instead")
    public typealias Config = RestJsonProtocolClient.RestJsonProtocolClientConfiguration
    public typealias Configuration = RestJsonProtocolClient.RestJsonProtocolClientConfig

    public required init(config: RestJsonProtocolClient.RestJsonProtocolClientConfig) {
        ClientRuntime.initialize()
        client = ClientRuntime.SdkHttpClient(engine: config.httpClientEngine, config: config.httpClientConfiguration)
        self.config = config
    }

    @available(*, deprecated, message: "Use init(config: RestJsonProtocolClient.RestJsonProtocolClientConfig) instead")
    public convenience init(config: RestJsonProtocolClient.RestJsonProtocolClientConfiguration) {
        do {
            try self.init(config: config.toSendable())
        } catch {
            // This should never happen since all values are already initialized in the class
            fatalError("Failed to convert deprecated configuration: \(error)")
        }
    }

    public convenience init() throws {
        let config = try RestJsonProtocolClient.RestJsonProtocolClientConfig()
        self.init(config: config)
    }

}

extension RestJsonProtocolClient {

    /// Client configuration for RestJsonProtocolClient
    ///
    /// Conforms to `Sendable` for safe concurrent access across threads.
    public struct RestJsonProtocolClientConfig: ClientRuntime.DefaultClientConfiguration & ClientRuntime.DefaultHttpClientConfiguration, Swift.Sendable {
        public var telemetryProvider: ClientRuntime.TelemetryProvider
        public var retryStrategyOptions: SmithyRetriesAPI.RetryStrategyOptions
        public var clientLogMode: ClientRuntime.ClientLogMode
        public var endpoint: Swift.String?
        public var idempotencyTokenGenerator: ClientRuntime.IdempotencyTokenGenerator
        public var httpClientEngine: SmithyHTTPAPI.HTTPClient
        public var httpClientConfiguration: ClientRuntime.HttpClientConfiguration
        public var authSchemes: SmithyHTTPAuthAPI.AuthSchemes?
        public var authSchemePreference: [String]?
        public var authSchemeResolver: SmithyHTTPAuthAPI.AuthSchemeResolver
        public var bearerTokenIdentityResolver: any SmithyIdentity.BearerTokenIdentityResolver
        // Interceptor providers with Sendable-safe internal storage
        private var _interceptorProviders: [ClientRuntime.SendableInterceptorProviderBox] = []
        public var interceptorProviders: [ClientRuntime.InterceptorProvider] {
            get {
                return _interceptorProviders
            }
            set {
                _interceptorProviders = newValue.map { ClientRuntime.SendableInterceptorProviderBox($0) }
            }
        }

        private var _httpInterceptorProviders: [ClientRuntime.SendableHttpInterceptorProviderBox] = []
        public var httpInterceptorProviders: [ClientRuntime.HttpInterceptorProvider] {
            get {
                return _httpInterceptorProviders
            }
            set {
                _httpInterceptorProviders = newValue.map { ClientRuntime.SendableHttpInterceptorProviderBox($0) }
            }
        }

        public init(
            telemetryProvider: ClientRuntime.TelemetryProvider? = nil,
            retryStrategyOptions: SmithyRetriesAPI.RetryStrategyOptions? = nil,
            clientLogMode: ClientRuntime.ClientLogMode? = nil,
            endpoint: Swift.String? = nil,
            idempotencyTokenGenerator: ClientRuntime.IdempotencyTokenGenerator? = nil,
            httpClientEngine: SmithyHTTPAPI.HTTPClient? = nil,
            httpClientConfiguration: ClientRuntime.HttpClientConfiguration? = nil,
            authSchemes: SmithyHTTPAuthAPI.AuthSchemes? = nil,
            authSchemePreference: [String]? = nil,
            authSchemeResolver: SmithyHTTPAuthAPI.AuthSchemeResolver? = nil,
            bearerTokenIdentityResolver: (any SmithyIdentity.BearerTokenIdentityResolver)? = nil,
            interceptorProviders: [ClientRuntime.InterceptorProvider]? = nil,
            httpInterceptorProviders: [ClientRuntime.HttpInterceptorProvider]? = nil
        ) throws {
            self.telemetryProvider = telemetryProvider ?? ClientRuntime.DefaultTelemetry.provider
            self.retryStrategyOptions = retryStrategyOptions ?? ClientRuntime.ClientConfigurationDefaults.defaultRetryStrategyOptions
            self.clientLogMode = clientLogMode ?? ClientRuntime.ClientConfigurationDefaults.defaultClientLogMode
            self.endpoint = endpoint
            self.idempotencyTokenGenerator = idempotencyTokenGenerator ?? ClientRuntime.ClientConfigurationDefaults.defaultIdempotencyTokenGenerator
            self.httpClientEngine = httpClientEngine ?? ClientRuntime.ClientConfigurationDefaults.makeClient(httpClientConfiguration: httpClientConfiguration ?? ClientRuntime.ClientConfigurationDefaults.defaultHttpClientConfiguration)
            self.httpClientConfiguration = httpClientConfiguration ?? ClientRuntime.ClientConfigurationDefaults.defaultHttpClientConfiguration
            self.authSchemes = authSchemes ?? []
            self.authSchemePreference = authSchemePreference ?? nil
            self.authSchemeResolver = authSchemeResolver ?? ClientRuntime.ClientConfigurationDefaults.defaultAuthSchemeResolver
            self.bearerTokenIdentityResolver = bearerTokenIdentityResolver ?? SmithyIdentity.StaticBearerTokenIdentityResolver(token: SmithyIdentity.BearerTokenIdentity(token: ""))
            self._interceptorProviders = (interceptorProviders ?? []).map { ClientRuntime.SendableInterceptorProviderBox($0) }
            self._httpInterceptorProviders = (httpInterceptorProviders ?? []).map { ClientRuntime.SendableHttpInterceptorProviderBox($0) }
        }

        public init() async throws {
            try await self.init(
                telemetryProvider: nil,
                retryStrategyOptions: nil,
                clientLogMode: nil,
                endpoint: nil,
                idempotencyTokenGenerator: nil,
                httpClientEngine: nil,
                httpClientConfiguration: nil,
                authSchemes: nil,
                authSchemePreference: nil,
                authSchemeResolver: nil,
                bearerTokenIdentityResolver: nil,
                interceptorProviders: nil,
                httpInterceptorProviders: nil
            )
        }

        public var partitionID: String? {
            return ""
        }

        public mutating func addInterceptorProvider(_ provider: ClientRuntime.InterceptorProvider) {
            self._interceptorProviders.append(ClientRuntime.SendableInterceptorProviderBox(provider))
        }

        public mutating func addInterceptorProvider(_ provider: ClientRuntime.HttpInterceptorProvider) {
            self._httpInterceptorProviders.append(ClientRuntime.SendableHttpInterceptorProviderBox(provider))
        }

    }

    @available(*, deprecated, message: "Use RestJsonProtocolClientConfig instead. This class will be removed in a future version.")
    public final class RestJsonProtocolClientConfiguration: ClientRuntime.DefaultClientConfiguration & ClientRuntime.DefaultHttpClientConfiguration {
        public var telemetryProvider: ClientRuntime.TelemetryProvider
        public var retryStrategyOptions: SmithyRetriesAPI.RetryStrategyOptions
        public var clientLogMode: ClientRuntime.ClientLogMode
        public var endpoint: Swift.String?
        public var idempotencyTokenGenerator: ClientRuntime.IdempotencyTokenGenerator
        public var httpClientEngine: SmithyHTTPAPI.HTTPClient
        public var httpClientConfiguration: ClientRuntime.HttpClientConfiguration
        public var authSchemes: SmithyHTTPAuthAPI.AuthSchemes?
        public var authSchemePreference: [String]?
        public var authSchemeResolver: SmithyHTTPAuthAPI.AuthSchemeResolver
        public var bearerTokenIdentityResolver: any SmithyIdentity.BearerTokenIdentityResolver
        // Interceptor providers with Sendable-safe internal storage
        private var _interceptorProviders: [ClientRuntime.SendableInterceptorProviderBox] = []
        public var interceptorProviders: [ClientRuntime.InterceptorProvider] {
            get {
                return _interceptorProviders
            }
            set {
                _interceptorProviders = newValue.map { ClientRuntime.SendableInterceptorProviderBox($0) }
            }
        }

        private var _httpInterceptorProviders: [ClientRuntime.SendableHttpInterceptorProviderBox] = []
        public var httpInterceptorProviders: [ClientRuntime.HttpInterceptorProvider] {
            get {
                return _httpInterceptorProviders
            }
            set {
                _httpInterceptorProviders = newValue.map { ClientRuntime.SendableHttpInterceptorProviderBox($0) }
            }
        }

        public init(
            telemetryProvider: ClientRuntime.TelemetryProvider? = nil,
            retryStrategyOptions: SmithyRetriesAPI.RetryStrategyOptions? = nil,
            clientLogMode: ClientRuntime.ClientLogMode? = nil,
            endpoint: Swift.String? = nil,
            idempotencyTokenGenerator: ClientRuntime.IdempotencyTokenGenerator? = nil,
            httpClientEngine: SmithyHTTPAPI.HTTPClient? = nil,
            httpClientConfiguration: ClientRuntime.HttpClientConfiguration? = nil,
            authSchemes: SmithyHTTPAuthAPI.AuthSchemes? = nil,
            authSchemePreference: [String]? = nil,
            authSchemeResolver: SmithyHTTPAuthAPI.AuthSchemeResolver? = nil,
            bearerTokenIdentityResolver: (any SmithyIdentity.BearerTokenIdentityResolver)? = nil,
            interceptorProviders: [ClientRuntime.InterceptorProvider]? = nil,
            httpInterceptorProviders: [ClientRuntime.HttpInterceptorProvider]? = nil
        ) throws {
            self.telemetryProvider = telemetryProvider ?? ClientRuntime.DefaultTelemetry.provider
            self.retryStrategyOptions = retryStrategyOptions ?? ClientRuntime.ClientConfigurationDefaults.defaultRetryStrategyOptions
            self.clientLogMode = clientLogMode ?? ClientRuntime.ClientConfigurationDefaults.defaultClientLogMode
            self.endpoint = endpoint
            self.idempotencyTokenGenerator = idempotencyTokenGenerator ?? ClientRuntime.ClientConfigurationDefaults.defaultIdempotencyTokenGenerator
            self.httpClientEngine = httpClientEngine ?? ClientRuntime.ClientConfigurationDefaults.makeClient(httpClientConfiguration: httpClientConfiguration ?? ClientRuntime.ClientConfigurationDefaults.defaultHttpClientConfiguration)
            self.httpClientConfiguration = httpClientConfiguration ?? ClientRuntime.ClientConfigurationDefaults.defaultHttpClientConfiguration
            self.authSchemes = authSchemes ?? []
            self.authSchemePreference = authSchemePreference ?? nil
            self.authSchemeResolver = authSchemeResolver ?? ClientRuntime.ClientConfigurationDefaults.defaultAuthSchemeResolver
            self.bearerTokenIdentityResolver = bearerTokenIdentityResolver ?? SmithyIdentity.StaticBearerTokenIdentityResolver(token: SmithyIdentity.BearerTokenIdentity(token: ""))
            self._interceptorProviders = (interceptorProviders ?? []).map { ClientRuntime.SendableInterceptorProviderBox($0) }
            self._httpInterceptorProviders = (httpInterceptorProviders ?? []).map { ClientRuntime.SendableHttpInterceptorProviderBox($0) }
        }

        public convenience init() async throws {
            try await self.init(
                telemetryProvider: nil,
                retryStrategyOptions: nil,
                clientLogMode: nil,
                endpoint: nil,
                idempotencyTokenGenerator: nil,
                httpClientEngine: nil,
                httpClientConfiguration: nil,
                authSchemes: nil,
                authSchemePreference: nil,
                authSchemeResolver: nil,
                bearerTokenIdentityResolver: nil,
                interceptorProviders: nil,
                httpInterceptorProviders: nil
            )
        }

        public var partitionID: String? {
            return ""
        }

        public func toSendable() throws -> RestJsonProtocolClientConfig {
            return try RestJsonProtocolClientConfig(
                telemetryProvider: self.telemetryProvider,
                retryStrategyOptions: self.retryStrategyOptions,
                clientLogMode: self.clientLogMode,
                endpoint: self.endpoint,
                idempotencyTokenGenerator: self.idempotencyTokenGenerator,
                httpClientEngine: self.httpClientEngine,
                httpClientConfiguration: self.httpClientConfiguration,
                authSchemes: self.authSchemes,
                authSchemePreference: self.authSchemePreference,
                authSchemeResolver: self.authSchemeResolver,
                bearerTokenIdentityResolver: self.bearerTokenIdentityResolver,
                interceptorProviders: self.interceptorProviders,
                httpInterceptorProviders: self.httpInterceptorProviders
            )
        }

        public func addInterceptorProvider(_ provider: ClientRuntime.InterceptorProvider) {
            self._interceptorProviders.append(ClientRuntime.SendableInterceptorProviderBox(provider))
        }

        public func addInterceptorProvider(_ provider: ClientRuntime.HttpInterceptorProvider) {
            self._httpInterceptorProviders.append(ClientRuntime.SendableHttpInterceptorProviderBox(provider))
        }

    }

    public static func builder() -> ClientRuntime.ClientBuilder<RestJsonProtocolClient> {
        return ClientRuntime.ClientBuilder<RestJsonProtocolClient>(defaultPlugins: [
            ClientRuntime.DefaultClientPlugin()
        ])
    }
}
"""
        contents.shouldContainOnlyOnce(expected)
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
                      .withOperationProperties(value: operation)
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
        var config = config
        let plugins: [any ClientRuntime.Plugin] = []
        for plugin in plugins {
            try await plugin.configureClient(clientConfiguration: &config)
        }
        let operation = RestJsonProtocolClient.allocateWidgetOperation
        let context = Smithy.ContextBuilder()
                      .withMethod(value: .post)
                      .withServiceName(value: serviceName)
                      .withOperation(value: "allocateWidget")
                      .withUnsignedPayloadTrait(value: false)
                      .withSmithyDefaultConfig(config)
                      .withOperationProperties(value: operation)
                      .build()
        let builder = ClientRuntime.OrchestratorBuilder<AllocateWidgetInput, AllocateWidgetOutput, SmithyHTTPAPI.HTTPRequest, SmithyHTTPAPI.HTTPResponse>()
        let clientProtocol = RPCv2CBOR.HTTPClientProtocol()
        builder.apply(operation, clientProtocol)
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
