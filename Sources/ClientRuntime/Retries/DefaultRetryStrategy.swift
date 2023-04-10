//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit
import struct Foundation.TimeInterval

public class DefaultRetryStrategy: RetryStrategy {
    let crtRetryStrategy: AwsCommonRuntimeKit.RetryStrategy
    private let sharedDefaultIO = SDKDefaultIO.shared

    // MARK: - init & deinit

    public required init(retryStrategyOptions: RetryStrategyOptions = RetryStrategyOptions()) throws {
        self.crtRetryStrategy = try AwsCommonRuntimeKit.RetryStrategy(
            retryStrategyOptions: retryStrategyOptions,
            eventLoopGroup: sharedDefaultIO.eventLoopGroup
        )
    }

    public convenience init(retryOptions: RetryOptions) throws {
        let retryStrategyOptions = RetryStrategyOptions(retryMode: retryOptions.retryMode, maxRetriesBase: retryOptions.maxAttempts)
        try self.init(retryStrategyOptions: retryStrategyOptions)
    }

    // MARK: - RetryStrategy protocol

    public func acquireInitialRetryToken(tokenScope: String) async throws -> RetryToken {
        let token = try await crtRetryStrategy.acquireToken(partitionId: tokenScope)
        return RetryToken(crtToken: token)
    }

    public func refreshRetryTokenForRetry(
        tokenToRenew: RetryToken,
        errorInfo: RetryErrorInfo
    ) async throws -> RetryToken {
        let token = try await crtRetryStrategy.scheduleRetry(
            token: tokenToRenew.crtToken,
            errorType: errorInfo.errorType.toCRTType()
        )
        return RetryToken(crtToken: token)
    }

    public func recordSuccess(token: RetryToken) {
        crtRetryStrategy.recordSuccess(token: token.crtToken)
    }

    // MARK: - Private methods

    private func hint(for httpResponse: HttpResponse?) -> TimeInterval? {
        guard let retryAfter = httpResponse?.headers.value(for: "x-amz-retry-after") else { return nil }
        guard let hint = TimeInterval(retryAfter) else { return nil }
        return hint
    }
}

extension AwsCommonRuntimeKit.RetryStrategy {

    convenience init(retryStrategyOptions: RetryStrategyOptions, eventLoopGroup: EventLoopGroup) throws {
       try self.init(
            eventLoopGroup: eventLoopGroup,
            initialBucketCapacity: 500,
            maxRetries: retryStrategyOptions.maxRetriesBase,
            backOffScaleFactor: 0.025,
            jitterMode: ExponentialBackOffJitterType.default.toCRTType(),
            generateRandom: nil // we should pass in the options.generateRandom but currently
                                // it fails since the underlying closure is a c closure
        )
    }
}
