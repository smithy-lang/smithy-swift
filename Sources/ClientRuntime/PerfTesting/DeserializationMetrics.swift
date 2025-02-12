//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public final class DeserializationMetrics {
    public static let shared = DeserializationMetrics()

    // Dictionary that maps an operation identifier to its recorded serialization times.
    private var _metrics: [String: [Double]] = [:]
    private let lock = NSLock()

    /// Record a serialization time for a given operation.
    public func record(time: Double, for operation: String) {
        lock.lock()
        defer { lock.unlock() }
        if var times = _metrics[operation] {
            times.append(time)
            _metrics[operation] = times
        } else {
            _metrics[operation] = [time]
        }
    }

    /// Retrieve the recorded times for a given operation.
    public func times(for operation: String) -> [Double] {
        lock.lock()
        defer { lock.unlock() }
        return _metrics[operation] ?? []
    }
}
