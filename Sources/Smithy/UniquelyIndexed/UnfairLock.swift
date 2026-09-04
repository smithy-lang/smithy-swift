//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Darwin)
import os
#else
import Glibc
#endif

/// A minimal mutual-exclusion lock.
///
/// This is used in place of `NSLock` on the serialization hot path.  `NSLock` is an Objective-C
/// object, so locking and unlocking it costs a message send each; the platform primitives used here
/// do not.
///
/// The lock is not recursive: a thread that locks it must not lock it again before unlocking.
///
/// The platform primitive is held behind a pointer allocated at init because both primitives require
/// a stable address, and Swift does not promise one for a stored property.
final class UnfairLock: @unchecked Sendable {

#if canImport(Darwin)

    private let handle: UnsafeMutablePointer<os_unfair_lock>

    init() {
        self.handle = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        self.handle.initialize(to: os_unfair_lock())
    }

    deinit {
        handle.deinitialize(count: 1)
        handle.deallocate()
    }

    func lock() {
        os_unfair_lock_lock(handle)
    }

    func unlock() {
        os_unfair_lock_unlock(handle)
    }

#else

    private let handle: UnsafeMutablePointer<pthread_mutex_t>

    init() {
        self.handle = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        let status = pthread_mutex_init(self.handle, nil)
        precondition(status == 0, "pthread_mutex_init failed with status \(status)")
    }

    deinit {
        let status = pthread_mutex_destroy(handle)
        precondition(status == 0, "pthread_mutex_destroy failed with status \(status)")
        handle.deallocate()
    }

    func lock() {
        pthread_mutex_lock(handle)
    }

    func unlock() {
        pthread_mutex_unlock(handle)
    }

#endif
}
