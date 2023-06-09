//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct DefaultSDKRuntimeConfiguration<DefaultSDKRuntimeRetryStrategy: RetryStrategy,
    DefaultSDKRuntimeRetryErrorInfoProvider: RetryErrorInfoProvider>: SDKRuntimeConfiguration {
    public typealias SDKRetryStrategy = DefaultSDKRuntimeRetryStrategy
    public typealias SDKRetryErrorInfoProvider = DefaultSDKRuntimeRetryErrorInfoProvider

    public var serviceName: String
    public var clientName: String
    public var encoder: RequestEncoder?
    public var decoder: ResponseDecoder?
    public var httpClientEngine: HttpClientEngine
    public var httpClientConfiguration: HttpClientConfiguration
    public var idempotencyTokenGenerator: IdempotencyTokenGenerator
    public var logger: LogAgent
    public var retryStrategyOptions: RetryStrategyOptions
    public var clientLogMode: ClientLogMode
    public var endpoint: String?

    public init(
        serviceName: String,
        clientName: String
    ) throws {
        self.serviceName = clientName
        self.clientName = clientName
        self.encoder = nil
        self.decoder = nil
        self.httpClientEngine = Self.defaultHttpClientEngine
        self.httpClientConfiguration = Self.defaultHttpClientConfiguration
        self.idempotencyTokenGenerator = Self.defaultIdempotencyTokenGenerator
        self.retryStrategyOptions = Self.defaultRetryStrategyOptions
        self.logger = Self.defaultLogger(clientName: clientName)
        self.clientLogMode = Self.defaultClientLogMode
    }
}

public extension DefaultSDKRuntimeConfiguration {

    static var defaultHttpClientEngine: HttpClientEngine { CRTClientEngine() }

    static var defaultHttpClientConfiguration: HttpClientConfiguration { HttpClientConfiguration() }

    static var defaultIdempotencyTokenGenerator: IdempotencyTokenGenerator { DefaultIdempotencyTokenGenerator() }

    static var defaultRetryStrategyOptions: RetryStrategyOptions { .default }

    static func defaultLogger(clientName: String) -> SwiftLogger {
        SwiftLogger(label: clientName)
    }

    static var defaultClientLogMode: ClientLogMode { .request }
}
