//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension NSLock {
    /// Execute a closure while holding the lock
    /// - Parameter closure: A closure to execute while holding the lock
    /// - Returns: The return value of the closure
    public func withLockingClosure<T>(closure: () -> T) -> T {
        lock()
        defer {
            unlock()
        }
        return closure()
    }

    /// Execute a throwing closure while holding the lock
    /// - Parameter closure: A throwing closure to execute while holding the lock 
    /// - Returns: The return value of the closure  
    public func withLockingThrowingClosure<T>(closure: () throws -> T) throws -> T {
        lock()
        defer {
            unlock()
        }
        return try closure()
    }
}
