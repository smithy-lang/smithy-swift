//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Foundation.NSRecursiveLock

extension NSRecursiveLock {

    /// Executes a closure while holding the lock.
    ///
    /// - Parameter closure: A closure to execute while holding the lock
    /// - Returns: The return value of the closure
    /// - Throws: Rethrows any error thrown by the closure.
    func withLockingClosure<T>(_ closure: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try closure()
    }
}
