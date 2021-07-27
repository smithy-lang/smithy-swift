/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

/// This class is used by the service clients as the base class for configuration.
/// At code generation time, a service client configuration is generated to inherit from this class.
/// Anything contained in this class should be basics that all service clients can set while anything
///  generated should be service specific.
//open class Configuration {
//    public var encoder: RequestEncoder?
//    public var decoder: ResponseDecoder?
//    public let httpClientEngine: HttpClientEngine
//    public let httpClientConfiguration: HttpClientConfiguration
//    public let idempotencyTokenGenerator: IdempotencyTokenGenerator
//    public let retrier: Retrier
//
//    public init(encoder: RequestEncoder? = nil,
//                decoder: ResponseDecoder? = nil,
//                httpClientEngine: HttpClientEngine? = nil,
//                httpClientConfiguration: HttpClientConfiguration = HttpClientConfiguration(),
//                retrier: Retrier? = nil,
//                idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws {
//        self.encoder = encoder
//        self.decoder = decoder
//        let engine = try httpClientEngine ?? CRTClientEngine()
//        self.httpClientEngine = engine
//        self.retrier = try retrier ?? SDKRetrier(clientEngine: engine)
//        self.httpClientConfiguration = httpClientConfiguration
//        self.idempotencyTokenGenerator = idempotencyTokenGenerator
//    }
//}

public protocol ClientRuntimeConfiguration {
    var encoder: RequestEncoder? {get}
    var decoder: ResponseDecoder? {get}
    var httpClientEngine: HttpClientEngine {get}
    var httpClientConfiguration: HttpClientConfiguration {get}
    var idempotencyTokenGenerator: IdempotencyTokenGenerator {get}
    var retrier: Retrier {get}
    var logger: LogAgent {get}
    var clientLogMode: ClientLogMode {get}
}

public extension ClientRuntimeConfiguration {
    var httpClientEngine: HttpClientEngine {
        get throws {
            return try CRTClientEngine()
        }
    }
    
    var httpClientConfiguration: HttpClientConfiguration {
        return HttpClientConfiguration()
    }
    
    var idempotencyTokenGenerator: IdempotencyTokenGenerator {
        return DefaultIdempotencyTokenGenerator()
    }
    
    var retrier: Retrier {
        get throws {
            return try SDKRetrier(clientEngine: httpClientEngine)
        }
    }
    
    
    var clientLogMode: ClientLogMode {
        return .request
    }
    
    var encoder: RequestEncoder? {
        get {
            return nil
        }
    }
    
    var decoder: ResponseDecoder? {
        get {
            return nil
        }
    }
}

public struct DefaultClientRuntimeConfiguration: ClientRuntimeConfiguration {
    public var retrier: Retrier
    
    public var httpClientEngine: HttpClientEngine
    
    public var logger: LogAgent
    
    public init(_ clientName: String) throws {
        let engine = try CRTClientEngine()
        self.httpClientEngine = engine
        self.retrier = try SDKRetrier(clientEngine: engine)
        self.logger = SwiftLogger(label: clientName)
    }
}

