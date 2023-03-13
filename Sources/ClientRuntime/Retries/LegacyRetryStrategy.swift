//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit
import struct Foundation.TimeInterval

public class LegacyRetryStrategy: RetryStrategy {
    let crtRetryStrategy: AwsCommonRuntimeKit.RetryStrategy
    private let sharedDefaultIO = SDKDefaultIO.shared

    public required init(retryStrategyOptions: RetryStrategyOptions = .standard) throws {
        self.crtRetryStrategy = try AwsCommonRuntimeKit.RetryStrategy(
            retryStrategyOptions: retryStrategyOptions,
            eventLoopGroup: sharedDefaultIO.eventLoopGroup
        )
    }

    public func acquireInitialRetryToken(tokenScope: String) async throws -> RetryToken {
        let token = try await crtRetryStrategy.acquireToken(partitionId: tokenScope)
        return RetryToken(crtToken: token)
    }

    public func refreshRetryTokenForRetry(tokenToRenew: RetryToken, errorInfo: RetryErrorInfo) async throws -> RetryToken {
        let token = try await crtRetryStrategy.scheduleRetry(token: tokenToRenew.crtToken, errorType: errorInfo.errorType.toCRTType())
        return RetryToken(crtToken: token)
    }

    public func recordSuccess(token: RetryToken) {
        crtRetryStrategy.recordSuccess(token: token.crtToken)
    }

    public func isErrorRetryable<E>(error: SdkError<E>) -> Bool {
        switch error {
        case .client(let clientError, _):
            switch clientError {
            case .networkError, .crtError:
                return true
            default:
                return false
            }
        case .service(let serviceError, let httpResponse):
            if httpResponse.headers.exists(name: "x-amz-retry-after") {
                return true
            }

            if let serviceError = serviceError as? ServiceError {
                return serviceError._retryable
            }

            if httpResponse.statusCode.isRetryable {
                return true
            }
            return false
        case .unknown:
            return false
        }
    }

    public func getErrorInfo<E>(error: SdkError<E>) -> RetryErrorInfo {
        switch error {
        case .client(let clientError, _):
            if case ClientError.crtError = clientError {
                return RetryErrorInfo(errorType: .transient, retryAfterHint: nil)
            }
            return RetryErrorInfo(errorType: .clientError, retryAfterHint: nil)
        case .service(let serviceError, let httpResponse):
            if let retryAfter = httpResponse.headers.value(for: "x-amz-retry-after") {
                let hint = TimeInterval(retryAfter)
                return RetryErrorInfo(errorType: .serverError, retryAfterHint: hint)
            }

            if let serviceError = serviceError as? ServiceError {
                if serviceError._isThrottling {
                    return RetryErrorInfo(errorType: .throttling, retryAfterHint: nil)
                }
                return RetryErrorInfo(errorType: .serverError, retryAfterHint: nil)
            }

            if httpResponse.statusCode.isRetryable {
                return RetryErrorInfo(errorType: .transient, retryAfterHint: nil)
            }
            return RetryErrorInfo(errorType: .serverError, retryAfterHint: nil)
        case .unknown:
            return RetryErrorInfo(errorType: .clientError, retryAfterHint: nil)
        }
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
