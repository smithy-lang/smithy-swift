//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval

/// A token that is used to track retry of operations.
///
/// The retry token contains all the state relevant to one request that is needed to manage retry
/// until the request succeeds or fails after zero or more retries.
public class DefaultRetryToken: RetryToken {

    /// The number of retry attempts that have been made using this token.
    /// Defaults to zero at the initial attempt, goes up by one for each subsequent attempt.
    public internal(set) var retryCount: Int = 0

    /// The delay, in seconds, to the next retry.
    public internal(set) var delay: TimeInterval? = nil

    /// The amount of quota capacity amount held by this token, if any.
    ///
    /// Tokens have nil capacity amount when created.  Quota value is set to a prescribed value when attempting a retry.
    var capacityAmount: Int?

    /// The quota for this token.  More than one token (i.e. for requests against the same endpoint) may share a quota.
    let quota: RetryQuota

    init(quota: RetryQuota) {
        self.quota = quota
    }
}
