//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct DefaultSDKRuntimeConfiguration: SDKRuntimeConfiguration {
    public let retryer: SDKRetryer
    public var clientLogMode: ClientLogMode
    public var logger: LogAgent

    public init(_ clientName: String, clientLogMode: ClientLogMode) throws {
        self.retryer = try SDKRetryer()
        self.logger = SwiftLogger(label: clientName)
        self.clientLogMode = clientLogMode
    }
}
