//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

public class SDKRetryer: Retryer {
 
    let crtRetryStrategy: CRTAWSRetryStrategy
    let logger: SwiftLogger
    
    public init(options: RetryOptions) throws {
        self.crtRetryStrategy = try CRTAWSRetryStrategy(options: options.toCRTType())
        self.logger = SwiftLogger(label: "SDKRetryer")
    }
    
    public convenience init() throws {
        let backOffOptions = ExponentialBackOffRetryOptions()
        let retryOptions = RetryOptions(backOffRetryOptions: backOffOptions)
        try self.init(options: retryOptions)
    }
    
    public func acquireToken(partitionId: String, onTokenAcquired: @escaping RetryToken<Token>) {
        let result = crtRetryStrategy.acquireToken(partitionId: partitionId)
        result.then { result in
            switch result {
            case .success(let token):
                onTokenAcquired(RetryTokenAdapter(crtToken: token), nil)
            case .failure(let err):
                onTokenAcquired(nil, err)
            }
        }
    }
    
    public func scheduleRetry(token: Token, error: RetryError, onScheduled: @escaping RetryToken<Token>) {
        guard let token = token as? RetryTokenAdapter else {
            logger.error("The type of token was incorrect and the token cannot be released.")
            return
        }
        let result = crtRetryStrategy.scheduleRetry(token: token.crtToken, errorType: error.toCRTType())
        result.then { result in
            switch result {
            case .success(let token):
                onScheduled(RetryTokenAdapter(crtToken: token), nil)
            case .failure(let err):
                onScheduled(nil, err)
            }
        }
    }
    
    public func recordSuccess(token: Token) {
        guard let token = token as? RetryTokenAdapter else {
            logger.error("The type of token was incorrect and success cannot be recorded.")
            return
        }
        crtRetryStrategy.recordSuccess(token: token.crtToken)
    }
    
    public func releaseToken(token: Token) {
        guard let token = token as? RetryTokenAdapter else {
            logger.error("The type of token was incorrect and the token cannot be released.")
            return
        }
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
            if httpResponse.headers.value(for: "x-amz-retry-after") != nil {
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
            if httpResponse.headers.value(for: "x-amz-retry-after") != nil {
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
