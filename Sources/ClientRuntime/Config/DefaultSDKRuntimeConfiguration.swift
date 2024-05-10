//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Provides configuration options for a Smithy-based service.
public struct DefaultSDKRuntimeConfiguration<DefaultSDKRuntimeRetryStrategy: RetryStrategy,
    DefaultSDKRuntimeRetryErrorInfoProvider: RetryErrorInfoProvider> {

    /// The name of this Smithy service.
    public var serviceName: String

    /// The name of the client this config configures.
    public var clientName: String

    /// The HTTP client to be used for HTTP connections.
    ///
    /// If none is provided, the AWS CRT HTTP client will be used.
    public var httpClientEngine: HTTPClient

    /// The HTTP client configuration.
    ///
    /// If none is provided, a default config will be used.
    public var httpClientConfiguration: HttpClientConfiguration

    /// The idempotency token generator to use.
    ///
    /// If none is provided. one will be provided that supplies UUIDs.
    public var idempotencyTokenGenerator: IdempotencyTokenGenerator

    /// Configuration for telemetry, including tracing, metrics, and logging.
    ///
    /// If none is provided, only a default logger provider will be used.
    public var telemetryProvider: TelemetryProvider

    /// The retry strategy options to be used.
    ///
    /// If none is provided, default retry options will be used.
    public var retryStrategyOptions: RetryStrategyOptions

    /// The log mode to use for client logging.
    ///
    /// If none is provided, `.request` will be used.
    public var clientLogMode: ClientLogMode

    /// The network endpoint to use.
    ///
    /// If none is provided, the service will select its own endpoint to use.
    public var endpoint: String?

    /// Creates a new configuration.
    /// - Parameters:
    ///   - serviceName: The name of the service being configured
    ///   - clientName: The name of the service client being configured
    public init(
        serviceName: String,
        clientName: String
    ) throws {
        self.serviceName = clientName
        self.clientName = clientName
        self.httpClientConfiguration = Self.defaultHttpClientConfiguration
        self.httpClientEngine = Self.makeClient(httpClientConfiguration: self.httpClientConfiguration)
        self.idempotencyTokenGenerator = Self.defaultIdempotencyTokenGenerator
        self.retryStrategyOptions = Self.defaultRetryStrategyOptions
        self.telemetryProvider = DefaultTelemetry.provider
        self.clientLogMode = Self.defaultClientLogMode
    }
}

// Provides defaults for various client config values.
// Exposing these as static properties/methods allows them to be used by custom config objects.
public extension DefaultSDKRuntimeConfiguration {

    /// The default HTTP client for the target platform, configured with the supplied configuration.
    ///
    /// - Parameter httpClientConfiguration: The configuration for the HTTP client.
    /// - Returns: The `CRTClientEngine` client on Mac & Linux platforms, returns `URLSessionHttpClient` on non-Mac Apple platforms.
    static func makeClient(
        httpClientConfiguration: HttpClientConfiguration = defaultHttpClientConfiguration
    ) -> HTTPClient {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(macOS)
        return URLSessionHTTPClient(httpClientConfiguration: httpClientConfiguration)
        #else
        let connectTimeoutMs = httpClientConfiguration.connectTimeout.map { UInt32($0 * 1000) }
        let socketTimeout = UInt32(httpClientConfiguration.socketTimeout)
        let config = CRTClientEngineConfig(
          connectTimeoutMs: connectTimeoutMs,
          crtTlsOptions: httpClientConfiguration.tlsConfiguration as? CRTClientTLSOptions,
          socketTimeout: socketTimeout
        )
        return CRTClientEngine(config: config)
        #endif
    }

    /// The HTTP client configuration to use when none is provided.
    ///
    /// Is the CRT HTTP client's configuration.
    static var defaultHttpClientConfiguration: HttpClientConfiguration { HttpClientConfiguration() }

    /// The idempotency token generator to use when none is provided.
    ///
    /// Defaults to one that provides UUIDs.
    static var defaultIdempotencyTokenGenerator: IdempotencyTokenGenerator { DefaultIdempotencyTokenGenerator() }

    /// The retry strategy options to use when none is provided.
    ///
    /// Defaults to options with the defaults defined in `RetryStrategyOptions`.
    static var defaultRetryStrategyOptions: RetryStrategyOptions { RetryStrategyOptions() }

    /// The log mode to use when none is provided
    ///
    /// Defaults to `.request`.
    static var defaultClientLogMode: ClientLogMode { .request }

    static var defaultAuthSchemeResolver: AuthSchemeResolver { DefaultAuthSchemeResolver() }
}

public class DefaultAuthSchemeResolverParameters: AuthSchemeResolverParameters {
    public var operation: String
    public init(operation: String) {
        self.operation = operation
    }
}

public class DefaultAuthSchemeResolver: AuthSchemeResolver {
    public func resolveAuthScheme(params: AuthSchemeResolverParameters) throws -> [AuthOption] {
        return []
    }

    public func constructParameters(context: HttpContext) throws -> AuthSchemeResolverParameters {
        guard let opName = context.getOperation() else {
            throw ClientError.dataNotFound(
                "Operation name not configured in middleware context for auth scheme resolver params construction.")
        }
        return DefaultAuthSchemeResolverParameters(operation: opName)
    }
}

public typealias ClientConfigurationDefaults
    = DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>
