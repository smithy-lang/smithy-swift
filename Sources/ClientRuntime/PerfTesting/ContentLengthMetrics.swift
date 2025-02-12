//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public final class ContentLengthMetrics {
    public static let shared = ContentLengthMetrics()

    // Dictionary that maps an operation identifier to its recorded serialization times.
    private var _metrics: [String: [Int]] = [:]
    private let lock = NSLock()

    /// Record a content length for a given operation.
    public func record(length: Int, for operation: String) {
        lock.lock()
        defer { lock.unlock() }
        if var lengths = _metrics[operation] {
            lengths.append(length)
            _metrics[operation] = lengths
        } else {
            _metrics[operation] = [length]
        }
    }

    /// Retrieve the recorded lengths for a given operation.
    public func lengths(for operation: String) -> [Int] {
        lock.lock()
        defer { lock.unlock() }
        return _metrics[operation] ?? []
    }
}
