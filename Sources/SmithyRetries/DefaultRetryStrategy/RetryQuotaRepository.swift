//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyRetriesAPI.RetryStrategyOptions

/// Holds multiple quotas, keyed by partition IDs.  One repository lives per
/// `DefaultRetryStrategy`; clients share token buckets across operations by
/// reusing the same retry strategy across the client's lifetime.
actor RetryQuotaRepository {
    let options: RetryStrategyOptions
    private var quotas = [String: RetryQuota]()

    init(options: RetryStrategyOptions) {
        self.options = options
    }

    /// Returns the quota for the given partition ID.  Subsequent calls for the
    /// same partition return the existing quota.
    func quota(partitionID: String) -> RetryQuota {
        if let quota = quotas[partitionID] {
            return quota
        } else {
            let newQuota = RetryQuota(options: options)
            quotas[partitionID] = newQuota
            return newQuota
        }
    }
}
