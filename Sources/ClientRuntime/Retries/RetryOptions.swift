//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Used to set the desired retry behavior for the SDK.
/// Some AWS SDKs have a `legacy` mode; since smithy-swift will have standardized
/// retry behavior at the time of `smithy-swift`'s general availability, `smithy-swift` has
/// no `legacy` mode.
public enum RetryMode {
    /// The default mode for retry.  This is generally exponential backoff, without congestion control applied.
    case standard
    /// An optional, experimental mode for retry.  This is generally exponential backoff,
    /// with congestion control applied per-service.
    case adaptive
}

public struct RetryOptions {
    public let retryMode: RetryMode
    public let maxAttempts: Int

    /// The retry strategy associated with this set of options.
    ///
    /// The caller need not provide this;
    /// `smithy-swift` will provide a default strategy based on the selected `retryMode`
    /// and `maxAttempts` values.
    ///
    /// A custom SDK based on `smithy-swift` may assign a custom retry strategy in place of the
    /// default one, if desired.
    @_spi(RetryOptions)
    public var retryStrategy: RetryStrategy?

    /// The retry error classifier associated with this set of options.
    ///
    /// The caller need not provide this;
    /// `smithy-swift` will provide a default error classifier based on the selected `retryMode`
    /// and `maxAttempts` values.
    ///
    /// A custom SDK based on `smithy-swift` may assign a custom retry error classifier in place of the
    /// default one, if desired.
    @_spi(RetryOptions)
    public var retryErrorClassifier: RetryErrorClassifier?

    public init(retryMode: RetryMode = .standard, maxAttempts: Int = 3) {
        self.retryMode = retryMode
        self.maxAttempts = maxAttempts
    }
}
