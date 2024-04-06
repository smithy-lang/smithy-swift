//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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
