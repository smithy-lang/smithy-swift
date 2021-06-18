//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

public class SDKRetrier: Retrier {
    let crtRetryStrategy: CRTAWSRetryStrategy
    
    public init(options: RetryOptions) throws {
        self.crtRetryStrategy = try CRTAWSRetryStrategy(options: options.toCRTType())
    }
    
    public convenience init(clientEngine: HttpClientEngine) throws {
        let backOffOptions = ExponentialBackOffRetryOptions(client: clientEngine)
        let retryOptions = RetryOptions(backOffRetryOptions: backOffOptions)
        try self.init(options: retryOptions)
    }
    
    public func acquireToken(partitionId: String) throws -> RetryToken {
        let result = crtRetryStrategy.acquireToken(partitionId: partitionId)
        let token = try result.get()
        return RetryToken(crtToken: token)
    }
    
    public func scheduleRetry(token: RetryToken, error: RetryError) throws -> RetryToken {
        let result = crtRetryStrategy.scheduleRetry(token: token.crtToken, errorType: error.toCRTType())
        let token = try result.get()
        return RetryToken(crtToken: token)
    }
    
    public func recordSuccess(token: RetryToken) {
        crtRetryStrategy.recordSuccess(token: token.crtToken)
    }
    
    public func releaseToken(token: RetryToken) {
        crtRetryStrategy.releaseToken(token: token.crtToken)
    }
    
    public func isErrorRetryable<E>(error: SdkError<E>) -> Bool {
        switch error {
        case .client(let clientError) :
            switch clientError {
            case .networkError:
                return true
            case .crtError:
                return true
            default:
                return false
            }
        case .service(let serviceError):
            let castedServiceError = serviceError as? ServiceError
            return castedServiceError?._retryable ?? false
        case .unknown:
            return false
        }
    }
    
    public func getErrorType<E>(error: SdkError<E>) -> RetryError {
        switch error {
        case .client(let clientError) :
            switch clientError {
            case .crtError:
                return .transient
            default:
                return .clientError
            }
        case .service(let serviceError):
            guard let castedServiceError = serviceError as? ServiceError else {
                return .serverError
            }
            if castedServiceError._isThrottling {
                return .throttling
            }
            return .serverError
        case .unknown:
            return .clientError
        }
    }
}

