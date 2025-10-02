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

    // Disable creation of new instances of this type.
    private init() {}

    func clockSkew(host: String) async -> TimeInterval? {
        clockSkewStorage[host]
    }
    
    /// Calls the passed block to modify the clock skew value for the passed host.
    ///
    /// Returns a `Bool` indicating whether the clock skew value changed.
    /// - Parameters:
    ///   - host: The host for which clock skew is to be updated.
    ///   - block: A block that accepts the previous clock skew value, and returns the updated value.
    /// - Returns: `true` if the clock skew value was changed, `false` otherwise.
    func setClockSkew(host: String, block: @Sendable (TimeInterval?) -> TimeInterval?) async -> Bool {
        let previousValue = clockSkewStorage[host]
        let newValue = block(previousValue)
        clockSkewStorage[host] = newValue
        return newValue != previousValue
    }

    /// Clears all saved clock skew values.  For use during testing.
    func clear() async {
        clockSkewStorage = [:]
    }
}
