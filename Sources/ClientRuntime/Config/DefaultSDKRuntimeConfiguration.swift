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

    /// The encoder to be used for encoding models.
    ///
    /// If none is provided, a default encoder will be used.
    public var encoder: RequestEncoder?

    /// The decoder to be used for decoding models.
    ///
    /// If none is provided, a default decoder will be used.
    public var decoder: ResponseDecoder?

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

    /// The logger to be used for client activity.
    ///
    /// If none is provided, the SDK's logger will be used.
    public var logger: LogAgent

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
        self.encoder = nil
        self.decoder = nil
        self.httpClientConfiguration = Self.defaultHttpClientConfiguration
        self.httpClientEngine = Self.makeClient(httpClientConfiguration: self.httpClientConfiguration)
        self.idempotencyTokenGenerator = Self.defaultIdempotencyTokenGenerator
        self.retryStrategyOptions = Self.defaultRetryStrategyOptions
        self.logger = Self.defaultLogger(clientName: clientName)
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
    static func makeClient(httpClientConfiguration: HttpClientConfiguration) -> HTTPClient {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(macOS)
        return URLSessionHTTPClient(httpClientConfiguration: httpClientConfiguration)
        #else
        let connectTimeoutMs = httpClientConfiguration.connectTimeout.map { UInt32($0 * 1000) }
        let socketTimeout = httpClientConfiguration.connectTimeout.map { UInt32($0) }
        let config = CRTClientEngineConfig(
          connectTimeoutMs: connectTimeoutMs,
          socketTimeout: socketTimeout,
          tlsContext: httpClientConfiguration.tlsContext
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

    /// The logger to use when none is provided
    /// - Parameter clientName: The name of the client being logged
    /// - Returns: A Swift logger with `clientName` as its label.
    static func defaultLogger(clientName: String) -> SwiftLogger { SwiftLogger(label: clientName) }

    /// The log mode to use when none is provided
    ///
    /// Defaults to `.request`.
    static var defaultClientLogMode: ClientLogMode { .request }
}
