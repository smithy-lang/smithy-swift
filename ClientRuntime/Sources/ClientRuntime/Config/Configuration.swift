/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

/// This class is used by the service clients as the base class for configuration.
/// At code generation time, a service client configuration is generated to inherit from this class.
/// Anything contained in this class should be basics that all service clients can set while anything generated should be service specific.
open class Configuration {
    public var encoder: RequestEncoder?
    public var decoder: ResponseDecoder?
    public let httpClientEngine: HttpClientEngine?
    public let httpClientConfiguration: HttpClientConfiguration
    
    public init(encoder: RequestEncoder? = nil,
                decoder: ResponseDecoder? = nil,
                httpClientEngine: HttpClientEngine? = nil,
                httpClientConfiguration: HttpClientConfiguration = HttpClientConfiguration()) {
        self.encoder = encoder
        self.decoder = decoder
        self.httpClientEngine = httpClientEngine
        self.httpClientConfiguration = httpClientConfiguration
    }
}
