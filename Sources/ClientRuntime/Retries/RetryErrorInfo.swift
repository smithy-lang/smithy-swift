//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval

public struct RetryErrorInfo: Equatable {

    public var errorType: RetryErrorType

    /// Protocol hint. This could come from HTTP’s ’retry-after’ header or something from MQTT or any other protocol that has the ability to
    /// convey retry info from a peer.
    public let retryAfterHint: TimeInterval?

    var isTimeout: Bool
}
