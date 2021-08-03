//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

public struct DefaultSDKRuntimeConfiguration: SDKRuntimeConfiguration {
    public var retrier: Retrier

    public var logger: LogAgent

    public init(_ clientName: String) throws {
        AwsCommonRuntimeKit.initialize()
        self.retrier = try SDKRetrier()
        self.logger = SwiftLogger(label: clientName)
    }
}
