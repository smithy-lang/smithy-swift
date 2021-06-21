/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

/// This class is used by the service clients as the base class for configuration.
/// At code generation time, a service client configuration is generated to inherit from this class.
/// Anything contained in this class should be basics that all service clients can set while anything
///  generated should be service specific.
open class Configuration {
    public var encoder: RequestEncoder?
    public var decoder: ResponseDecoder?
    public let httpClientEngine: HttpClientEngine
    public let httpClientConfiguration: HttpClientConfiguration
    public let idempotencyTokenGenerator: IdempotencyTokenGenerator
    public let retrier: Retrier
    public let clientLogMode: ClientLogMode
    public let logger: LogAgent
    
    public init(encoder: RequestEncoder? = nil,
                decoder: ResponseDecoder? = nil,
                httpClientEngine: HttpClientEngine? = nil,
                httpClientConfiguration: HttpClientConfiguration = HttpClientConfiguration(),
                retrier: Retrier? = nil,
                clientLogMode: ClientLogMode = .request,
                logger: LogAgent? = nil,
                idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws {
        self.encoder = encoder
        self.decoder = decoder
        let engine = try httpClientEngine ?? CRTClientEngine()
        self.httpClientEngine = engine
        self.retrier = try retrier ?? SDKRetrier(clientEngine: engine)
        self.clientLogMode = clientLogMode
        self.logger = logger ?? SwiftLogger(label: "Swift SDK Logger")
        self.httpClientConfiguration = httpClientConfiguration
        self.idempotencyTokenGenerator = idempotencyTokenGenerator
    }
}
