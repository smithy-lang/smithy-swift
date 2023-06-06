//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

protocol Retryer {
    func acquireToken(partitionId: String) async throws -> RetryToken
    func scheduleRetry(token: RetryToken, error: RetryError) async throws -> RetryToken
    func recordSuccess(token: RetryToken)
    @available(*, deprecated, message: "This function will be removed soon.")
    func releaseToken(token: RetryToken)
    func isErrorRetryable(error: Error) -> Bool
    func getErrorType(error: Error) -> RetryError
}
