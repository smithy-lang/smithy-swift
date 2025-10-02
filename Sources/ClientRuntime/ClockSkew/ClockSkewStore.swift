//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval

/// Serves as a concurrency-safe repository for recorded clock skew values, keyed by hostname.
///
/// Storing clock skew values in a shared repository allows future operations to include the clock skew
/// correction on their initial attempt.  It also allows multiple clients to share clock skew values.
actor ClockSkewStore {
    static let shared = ClockSkewStore()

    /// Stores clock skew values, keyed by hostname.
    private var clockSkewStorage = [String: TimeInterval]()

    private init() {}

    func clockSkew(host: String) async -> TimeInterval? {
        clockSkewStorage[host]
    }

    func setClockSkew(host: String, block: (TimeInterval?) -> TimeInterval?) {
        clockSkewStorage[host] = block(clockSkewStorage[host])
    }

    /// Clears all saved clock skew values.  For use during testing.
    func clear() async {
        clockSkewStorage = [:]
    }
}
