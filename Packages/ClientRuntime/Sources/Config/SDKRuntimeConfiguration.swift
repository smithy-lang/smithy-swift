/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

/// At code generation time, a service client configuration is generated to implement this protocol to create
/// a concrete configuration type with defaults or allow the customer to pass in their own.
/// Anything contained in this protocol should be basics that all service clients can set while anything
/// generated should be service specific.
public protocol SDKRuntimeConfiguration {
    var encoder: RequestEncoder? {get}
    var decoder: ResponseDecoder? {get}
    var httpClientEngine: HttpClientEngine {get}
    var httpClientConfiguration: HttpClientConfiguration {get}
    var idempotencyTokenGenerator: IdempotencyTokenGenerator {get}
    var retrier: Retrier {get}
    var logger: LogAgent {get}
    var clientLogMode: ClientLogMode {get}
}

public extension SDKRuntimeConfiguration {
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

public struct DefaultSDKRuntimeConfiguration: SDKRuntimeConfiguration {
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

