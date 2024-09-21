//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Foundation.NSRecursiveLock

@propertyWrapper
public final class Indirect<T: Sendable>: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var _wrappedValue: Optional<T>

    public var wrappedValue: Optional<T> {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _wrappedValue
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _wrappedValue = newValue
        }
    }

    public init(wrappedValue: Optional<T>) {
        self._wrappedValue = wrappedValue
    }
}

extension Indirect: Equatable where T: Equatable {

    public static func ==(lhs: Indirect<T>, rhs: Indirect<T>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}
