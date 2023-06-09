//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

actor RetryQuotaRepository {
    private var quotas = [String: RetryQuota]()

    func quota(partitionID: String) -> RetryQuota {
        if let quota = quotas[partitionID] {
            return quota
        } else {
            let newQuota = RetryQuota()
            quotas[partitionID] = newQuota
            return newQuota
        }
    }
}
