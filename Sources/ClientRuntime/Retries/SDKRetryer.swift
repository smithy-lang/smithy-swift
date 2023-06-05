//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

public class SDKRetryer: Retryer {
    let crtRetryStrategy: AwsCommonRuntimeKit.RetryStrategy
    private let sharedDefaultIO = SDKDefaultIO.shared

    public init(options: RetryOptions = RetryOptions()) throws {
        self.crtRetryStrategy = try AwsCommonRuntimeKit.RetryStrategy(
            options: options,
            eventLoopGroup: sharedDefaultIO.eventLoopGroup
        )
    }

    public func acquireToken(partitionId: String) async throws -> RetryToken {
        let token = try await crtRetryStrategy.acquireToken(partitionId: partitionId)
        return RetryToken(crtToken: token)
    }

    public func scheduleRetry(token: RetryToken, error: RetryError) async throws -> RetryToken {
        let token = try await crtRetryStrategy.scheduleRetry(token: token.crtToken, errorType: error.toCRTType())
        return RetryToken(crtToken: token)
    }

    public func recordSuccess(token: RetryToken) {
        crtRetryStrategy.recordSuccess(token: token.crtToken)
    }

    @available(*, deprecated, message: "This function will be removed soon.")
    public func releaseToken(token: RetryToken) {
    }

    public func isErrorRetryable(error: Error) -> Bool {
        switch error {
        case is ClientError, is CRTError:
            return true
        case let error as ModeledError:
            return type(of: error).isRetryable
        case let error as HTTPError:
            if error.httpResponse.statusCode.isRetryable { return true }
            if error.httpResponse.headers.exists(name: "x-amz-retry-after") { return true }
        default:
            break
        }
        return false
    }

    public func getErrorType(error: Error) -> RetryError {
        switch error {
        case is CRTError:
            return .transient
        case is ClientError:
            return .clientError
        case let error as ModeledError:
            if type(of: error).isThrottling { return .throttling }
            if type(of: error).isRetryable { return .transient }
            return type(of: error).fault == .client ? .clientError : .serverError
        case let error as HTTPError:
            if error.httpResponse.headers.exists(name: "x-amz-retry-after") { return .serverError }
        default:
            break
        }
        return .clientError
    }
}

extension AwsCommonRuntimeKit.RetryStrategy {
    convenience init(options: RetryOptions, eventLoopGroup: EventLoopGroup) throws {
       try self.init(
            eventLoopGroup: eventLoopGroup,
            initialBucketCapacity: options.initialBucketCapacity,
            maxRetries: options.maxRetries,
            backOffScaleFactor: options.backOffScaleFactor,
            jitterMode: options.jitterMode.toCRTType(),
            generateRandom: nil // we should pass in the options.generateRandom but currently
                                // it fails since the underlying closure is a c closure
        )
    }
}
