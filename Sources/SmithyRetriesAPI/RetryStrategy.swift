//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol RetryStrategy {
    associatedtype Token: RetryToken

    init(options: RetryStrategyOptions)

    /// Called before any retries (for the first call to the operation).
    /// It either returns a retry token or an error upon the failure to
    /// acquire a token prior.
    /// tokenScope is arbitrary and out of scope for this component.
    /// However, adding it here offers us a lot of future flexibility * for outage detection. For example , it could be "us-east -1"
    /// on a shared retry strategy, or "us-west-2-c:dynamodb".
    func acquireInitialRetryToken(tokenScope: String) async throws -> Token

    /// After a failed operation call, this function is invoked to refresh the retryToken returned by acquireInitialRetryToken(). This
    /// function can either choose to allow another retry and send a new
    /// or updated token, or reject the retry attempt and report the error either in an exception or returning an error.
    func refreshRetryTokenForRetry(tokenToRenew: Token, errorInfo: RetryErrorInfo) async throws

    /// Upon successful completion of the operation, a user calls this
    /// function to record that the operation was successful.
    func recordSuccess(token: Token) async
}
