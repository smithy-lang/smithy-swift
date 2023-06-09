//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// For each service, a concrete service client configuration class is generated to implement the SDKRuntimeConfiguration protocol.
/// This generated concrete class provides a mechanism to adopt defaults or override by injection any of the parameters.
/// If this concrete class is not sufficient for your use case, you have the ability to write a concrete class that conforms to SDKRuntimeConfiguration.
public protocol SDKRuntimeConfiguration {
    associatedtype SDKRetryStrategy: RetryStrategy
    associatedtype SDKRetryErrorInfoProvider: RetryErrorInfoProvider

    init(serviceName: String, clientName: String) throws

    var encoder: RequestEncoder? { get }
    var decoder: ResponseDecoder? { get }
    var httpClientEngine: HttpClientEngine { get }
    static var defaultHttpClientEngine: HttpClientEngine { get }
    var httpClientConfiguration: HttpClientConfiguration { get }
    static var defaultHttpClientConfiguration: HttpClientConfiguration { get }
    var idempotencyTokenGenerator: IdempotencyTokenGenerator { get }
    static var defaultIdempotencyTokenGenerator: IdempotencyTokenGenerator { get }
    var logger: LogAgent { get }
    static func defaultLogger(clientName: String) -> SwiftLogger
    var clientLogMode: ClientLogMode { get }
    static var defaultClientLogMode: ClientLogMode { get }
    var retryStrategyOptions: RetryStrategyOptions { get }
    static var defaultRetryStrategyOptions: RetryStrategyOptions { get }
    var endpoint: String? { get set }
}
