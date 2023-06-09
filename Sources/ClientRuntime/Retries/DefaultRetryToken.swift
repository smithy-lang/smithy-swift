//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval

public class DefaultRetryToken: RetryToken {
    public internal(set) var retryCount: Int = 0
    public internal(set) var delay: TimeInterval = 0.0

    /// The amount of quota value held by this token, if any.
    /// Quota value is set when attempting a retry.
    var capacityAmount: Int?

    /// The quota for this token.  More than one token may share a quota.
    let quota: RetryQuota

    init(quota: RetryQuota) {
        self.quota = quota
    }
}
