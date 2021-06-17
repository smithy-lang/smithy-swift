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
    public let retryer: Retryer
    
    public init(encoder: RequestEncoder? = nil,
                decoder: ResponseDecoder? = nil,
                httpClientEngine: HttpClientEngine? = nil,
                httpClientConfiguration: HttpClientConfiguration = HttpClientConfiguration(),
                retryer: Retryer? = nil,
                idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws {
        self.encoder = encoder
        self.decoder = decoder
        if let httpClientEngine = httpClientEngine {
            self.httpClientEngine = httpClientEngine
        } else {
            // CRT is the default engine
            self.httpClientEngine = try CRTClientEngine()
        }
        if let retryer = retryer {
            self.retryer = retryer
        } else {
            self.retryer = try SDKRetryer(clientEngine: self.httpClientEngine)
        }
        
        self.httpClientConfiguration = httpClientConfiguration
        self.idempotencyTokenGenerator = idempotencyTokenGenerator
    }
}
