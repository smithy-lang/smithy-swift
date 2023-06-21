//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Holds multiple quotas, keyed by partition IDs.
actor RetryQuotaRepository {
    let options: RetryStrategyOptions
    private var quotas = [String: RetryQuota]()

    init(options: RetryStrategyOptions) {
        self.options = options
    }

    /// Returns the quota for the given partition ID.
    ///
    /// The same partition ID will always get the same quota in response.
    /// - Parameter partitionID: The partition ID for the quota.
    /// - Returns: The quota for the partition ID.  If no quota yet exists for the given partition ID,
    /// one is created, stored, and returned.
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
