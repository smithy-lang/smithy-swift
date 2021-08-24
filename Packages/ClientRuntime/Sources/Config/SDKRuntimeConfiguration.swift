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
    var encoder: RequestEncoder? {get}
    var decoder: ResponseDecoder? {get}
    var httpClientEngine: HttpClientEngine {get}
    var httpClientConfiguration: HttpClientConfiguration {get}
    var idempotencyTokenGenerator: IdempotencyTokenGenerator {get}
    var retryer: Retryer {get}
    var logger: LogAgent {get}
    var clientLogMode: ClientLogMode {get}
}

public extension SDKRuntimeConfiguration {
    var httpClientEngine: HttpClientEngine {
        return CRTClientEngine()
    }
    
    var httpClientConfiguration: HttpClientConfiguration {
        return HttpClientConfiguration()
    }
    
    var idempotencyTokenGenerator: IdempotencyTokenGenerator {
        return DefaultIdempotencyTokenGenerator()
    }
    
    var clientLogMode: ClientLogMode {
        return .request
    }
    
    var encoder: RequestEncoder? {
        return nil
    }
    
    var decoder: ResponseDecoder? {
        return nil
    }
}
