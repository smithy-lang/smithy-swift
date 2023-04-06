//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// `RetryStrategy` defines the interface for a type that controls the operation's retry behavior.
/// > Note: Based on _The Design and Implementation of the AWS SDKs_ section 3.2.1, The Smithy Retry Interface, `RetryStrategy`.
public protocol RetryStrategy {

    init(retryStrategyOptions: RetryStrategyOptions) throws

    /// Obtains a retry token for the performance of this operation.
    ///
    /// This method should be called, and a retry token obtained, prior to the initial performance of the operation.
    /// If a token cannot be obtained, then an appropriate error is thrown back to the caller.
    ///
    /// From Smithy Reference Architecture docs:
    ///
    /// Called before any retries (for the first call to the operation).
    /// It either returns a retry token or an error upon the failure to
    /// acquire a token prior.
    /// tokenScope is arbitrary and out of scope for this component.
    /// However, adding it here offers us a lot of future flexibility
    /// for outage detection. For example , it could be "us-east -1"
    /// on a shared retry strategy, or "us-west-2-c:dynamodb".
    /// - Parameter tokenScope: The string identifier for the pool of tokens from which to obtain a refresh token. (Sometimes referred to as `partitionID`). Tokens obtained using different token scopes do not count against each other for congestion control purposes.
    /// - Returns: A `RetryToken`.
    /// - Throws: Error if a retry token could not be obtained.
    func acquireInitialRetryToken(tokenScope: String) async throws -> RetryToken

    /// Renews a retry token so that a retry may be safely performed.  For Swift, a new, refreshed retry token is returned rather than modifying the original that was passed into this method.
    ///
    /// From Smithy Reference Architecture docs:
    ///
    /// After a failed operation call, this function is invoked to refresh
    /// the retryToken returned by acquireInitialRetryToken(). This
    /// function can either choose to allow another retry and send a new
    /// or updated token, or reject the retry attempt and report the error
    /// either in an exception or returning an error.
    /// - Parameters:
    ///   - tokenToRenew: The `RetryToken` that was obtained before the initial attempt of this operation.
    ///   - errorInfo: The `RetryErrorInfo` for the error that prompted this retry.
    /// - Returns: A `RetryToken` that is refreshed for re-performance of the passed retry token.
    /// - Throws: Error if `tokenToRenew` could not be refreshed.
    func refreshRetryTokenForRetry(tokenToRenew: RetryToken, errorInfo: RetryErrorInfo) async throws -> RetryToken

    /// Indicates that the operation for this `RetryToken` was completed successfully so that the associated resources may be returned to the pool.
    ///
    /// From Smithy Reference Architecture docs:
    ///
    /// Upon successful completion of the operation, a user calls this
    /// function to record that the operation was successful.
    /// - Parameter token: The token for the operation that was completed successfully.
    func recordSuccess(token: RetryToken)
}
