//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

public class SDKRetryer: Retryer {
    let crtRetryStrategy: CRTAWSRetryStrategy
    
    public init(options: RetryOptions) throws {
        self.crtRetryStrategy = try CRTAWSRetryStrategy(options: options.toCRTType())
    }
    
    public convenience init() throws {
        let backOffOptions = ExponentialBackOffRetryOptions()
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
        case .client(let clientError, _) :
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
    
    public func getErrorType<E>(error: SdkError<E>) -> RetryError {
        switch error {
        case .client(let clientError, _) :
            if case ClientError.crtError = clientError {
                return .transient
            }
            return .clientError

        case .service(let serviceError, let httpResponse):
            if httpResponse.headers.exists(name: "x-amz-retry-after") {
                return .serverError
            }
            
            if let serviceError = serviceError as? ServiceError {
                if serviceError._isThrottling {
                    return .throttling
                }
                return .serverError
            }
            
            if httpResponse.statusCode.isRetryable {
                return .transient
            }
            
            return .serverError
        case .unknown:
            return .clientError
        }
    }
}
