//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval

public struct RetryErrorInfo: Equatable {

    /// The general nature of the cause of this retryable error.
    public var errorType: RetryErrorType

    /// Protocol hint. This could come from HTTP’s ’retry-after’ header or something from MQTT or any other protocol that has the ability to
    /// convey retry info from a peer.
    public let retryAfterHint: TimeInterval?

    /// Whether this error is a network timeout error.
    public var isTimeout: Bool

    public init(errorType: RetryErrorType, retryAfterHint: TimeInterval?, isTimeout: Bool) {
        self.errorType = errorType
        self.retryAfterHint = retryAfterHint
        self.isTimeout = isTimeout
    }
}
