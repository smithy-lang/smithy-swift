//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum RetryMode {
    case legacy
    case standard
    case adaptive
}

public struct RetryOptions {
    public let retryMode: RetryMode
    public let maxAttempts: Int
    public var retryStrategy: RetryStrategy?
    public var retryErrorClassifier: RetryErrorClassifier?

    public init(retryOptions: RetryOptions) {
        self.retryMode = retryOptions.retryMode
        self.maxAttempts = retryOptions.maxAttempts
    }

    public init(retryMode: RetryMode = .legacy, maxAttempts: Int = 3) {
        self.retryMode = retryMode
        self.maxAttempts = maxAttempts
    }
}
