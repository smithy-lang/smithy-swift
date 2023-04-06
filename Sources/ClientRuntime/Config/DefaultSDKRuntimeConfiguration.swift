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
    public var retryOptions: RetryOptions
    public var clientLogMode: ClientLogMode
    public var endpoint: String?

    /// The partition ID to be used for this configuration.
    ///
    /// Requests made with the same partition ID will be grouped together for retry throttling purposes.
    /// If no partition ID is provided, requests will be partitioned based on the hostname.
    public var partitionID: String?

    public init(
        _ clientName: String,
        clientLogMode: ClientLogMode = .request,
        partitionID: String? = nil
    ) throws {
        self.encoder = nil
        self.decoder = nil
        self.httpClientEngine = CRTClientEngine()
        self.httpClientConfiguration = HttpClientConfiguration()
        self.idempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()
        self.retryOptions = DefaultRetryOptions()
        self.logger = SwiftLogger(label: clientName)
        self.clientLogMode = clientLogMode
        self.partitionID = partitionID
    }
}
