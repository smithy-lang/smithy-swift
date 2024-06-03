//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyRetriesAPI.RetryStrategy
import protocol SmithyRetriesAPI.RetryToken
import struct SmithyRetriesAPI.RetryStrategyOptions
import struct SmithyRetriesAPI.RetryErrorInfo
import enum SmithyRetriesAPI.RetryError

@testable import ClientRuntime

public struct MockRetryStrategy: RetryStrategy {
    public typealias Token = MockRetryToken

    public init(options: RetryStrategyOptions) {
    }

    public func acquireInitialRetryToken(tokenScope: String) async throws -> MockRetryToken {
        return MockRetryToken()
    }

    public func refreshRetryTokenForRetry(tokenToRenew: MockRetryToken, errorInfo: RetryErrorInfo) async throws {
        throw RetryError.maxAttemptsReached
    }

    public func recordSuccess(token: MockRetryToken) async {
    }
}

public class MockRetryToken: RetryToken {
    public let retryCount: Int = 0
}
