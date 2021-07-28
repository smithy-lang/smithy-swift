//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct DefaultSDKRuntimeConfiguration: SDKRuntimeConfiguration {
    public var retrier: Retrier

    public var logger: LogAgent

    public init(_ clientName: String) throws {
        self.retrier = try SDKRetrier()
        self.logger = SwiftLogger(label: clientName)
    }
}
