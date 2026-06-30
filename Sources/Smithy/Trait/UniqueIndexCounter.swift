//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Foundation.NSRecursiveLock

public class UniqueIndexCounter {
    private var _counter = 0
    private let _lock = NSRecursiveLock()

    public init() {}

    public func getNextIndex() -> Int {
        _lock.lock()
        defer {
            _counter += 1
            _lock.unlock()
        }
        return _counter
    }
}
