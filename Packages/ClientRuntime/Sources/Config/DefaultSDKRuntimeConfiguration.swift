//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct DefaultSDKRuntimeConfiguration: SDKRuntimeConfiguration {
    public var endpoint: String?
    public let retryer: SDKRetryer
    public var clientLogMode: ClientLogMode
    public var logger: LogAgent

    public init(_ clientName: String, clientLogMode: ClientLogMode = .request) throws {
        self.retryer = try SDKRetryer()
        self.logger = SwiftLogger(label: clientName)
        self.clientLogMode = clientLogMode
    }
}
