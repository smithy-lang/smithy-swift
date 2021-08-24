//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
        
public protocol Retryer {
    func acquireToken(partitionId: String, onTokenAcquired: @escaping RetryToken<Token>)
    func scheduleRetry(token: Token, error: RetryError, onScheduled: @escaping RetryToken<Token>)
    func recordSuccess(token: Token)
    func releaseToken(token: Token)
    func isErrorRetryable<E>(error: SdkError<E>) -> Bool
    func getErrorType<E>(error: SdkError<E>) -> RetryError
}

public typealias RetryToken<T> = (T?, Error?) -> Void

public protocol Token {}
