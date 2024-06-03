//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval

/// A set of information fields that are derived from an error thrown when connecting to a service.
///
/// The `RetryErrorInfoProvider` creates an instance of this structure, which is then used by the
/// `RetryStrategy` to determine whether & how to retry a failed attempt.
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
