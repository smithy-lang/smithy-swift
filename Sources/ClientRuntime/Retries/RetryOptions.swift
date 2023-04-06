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

public protocol RetryOptions {
    var maxAttempts: Int { get }
    var retryMode: RetryMode { get }

    func makeRetryFactory() -> RetryFactory
}

public protocol RetryFactory {
    func makeRetryStrategy() throws -> RetryStrategy
    func makeRetryErrorClassifier() throws -> RetryErrorClassifying
}
