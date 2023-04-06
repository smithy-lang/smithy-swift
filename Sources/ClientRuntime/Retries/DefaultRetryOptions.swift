//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct DefaultRetryOptions: RetryOptions {
    public let retryMode: RetryMode
    public let maxAttempts: Int

    public init(retryOptions: RetryOptions) {
        self.retryMode = retryOptions.retryMode
        self.maxAttempts = retryOptions.maxAttempts
    }

    public init(retryMode: RetryMode = .legacy, maxAttempts: Int = 3) {
        self.retryMode = retryMode
        self.maxAttempts = maxAttempts
    }

    public func makeRetryFactory() -> RetryFactory {
        return DefaultRetryFactory(retryOptions: self)
    }
}

struct DefaultRetryFactory: RetryFactory {
    let retryOptions: RetryOptions

    init(retryOptions: RetryOptions) {
        self.retryOptions = retryOptions
    }

    /// Returns a retry strategy configured per these options.
    /// - Returns: A retry strategy suitable for this service.  Throws an error if the retry strategy cannot be created.
    public func makeRetryStrategy() throws -> RetryStrategy {
        let retryStrategyOptions = RetryStrategyOptions(maxRetriesBase: retryOptions.maxAttempts)
        return try LegacyRetryStrategy(retryStrategyOptions: retryStrategyOptions)
    }

    /// Returns an error classifier that can be used to classify operation errors for purposes of determining how & if to retry the request.
    /// - Returns: An instance of `RetryErrorClassifier` that should be used with this retry strategy.
    public func makeRetryErrorClassifier() throws -> RetryErrorClassifying {
        return RetryErrorClassifier()
    }
}
