//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Foundation.NSRecursiveLock

/// A type that returns unique integer index values to callers.
///
/// Unique index values start at zero and go up by one each time `getNextIndex()` is called.
/// This type is thread-safe and concurrency-safe.
public class UniqueIndexCounter {
    private var _counter = 0
    private let _lock = NSRecursiveLock()

    public init() {}

    /// Returns the next sequential unique index value for this counter.
    /// - Returns: The next sequential unique index value for this counter.
    public func getNextIndex() -> Int {
        _lock.lock()
        defer {
            _counter += 1
            _lock.unlock()
        }
        return _counter
    }
}
