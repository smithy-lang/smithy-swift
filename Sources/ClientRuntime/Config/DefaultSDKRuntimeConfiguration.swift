//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct DefaultSDKRuntimeConfiguration: SDKRuntimeConfiguration {
    public var encoder: RequestEncoder?
    public var decoder: ResponseDecoder?
    public var httpClientEngine: HttpClientEngine
    public var httpClientConfiguration: HttpClientConfiguration
    public var idempotencyTokenGenerator: IdempotencyTokenGenerator
    public var logger: LogAgent
    public let retryer: SDKRetryer
    public var clientLogMode: ClientLogMode
    public var endpoint: String?
    
    public init(
        _ clientName: String,
        clientLogMode: ClientLogMode = .request
    ) throws {
        self.encoder = nil
        self.decoder = nil
        self.httpClientEngine = CRTClientEngine(sdkIO: try SDKDefaultIO())
        self.httpClientConfiguration = HttpClientConfiguration()
        self.idempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()
        self.retryer = try SDKRetryer()
        self.logger = SwiftLogger(label: clientName)
        self.clientLogMode = clientLogMode
    }
}
