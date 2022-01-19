//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
        
protocol Retryer {
    func acquireToken(partitionId: String) throws -> RetryToken
    func scheduleRetry(token: RetryToken, error: RetryError) throws -> RetryToken
    func recordSuccess(token: RetryToken)
    func releaseToken(token: RetryToken)
    func isErrorRetryable<E>(error: SdkError<E>) -> Bool
    func getErrorType<E>(error: SdkError<E>) -> RetryError
}
