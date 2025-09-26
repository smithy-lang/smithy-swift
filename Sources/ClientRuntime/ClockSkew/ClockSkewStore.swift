//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval

/// Serves as a concurrency-safe repository for recorded clock skew values.
actor ClockSkewStore {
    static let shared = ClockSkewStore()

    /// Stores clock skew values, keyed by hostname.
    var clockSkewStorage = [String: TimeInterval]()

    init() {}

    func clockSkew(host: String) async -> TimeInterval? {
        clockSkewStorage[host]
    }

    func setClockSkew(host: String, value: TimeInterval) async {
        clockSkewStorage[host] = value
    }

    func clear() async {
        clockSkewStorage = [:]
    }
}
