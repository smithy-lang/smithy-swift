//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Foundation.NSLock

/// A mutable collection of uniquely indexed values that provides O(1) access to elements.
///
/// Elements are stored in a sparse array of pointers to elements, at their own unique index in the sparse array.
/// A lock is used to enforce exclusive access to `_storage`.  The type is designed to lock for as little time
/// as possible, so as to not cause problems in Swift concurrency.
///
/// A non-recursive lock is used because no method on this type acquires the lock while already holding it;
/// it is roughly twice as fast as a recursive lock, and access to this type is on the serialization hot path.
final class UniquelyIndexedMutableCollection: @unchecked Sendable {
    private var _storage: [(any UniquelyIndexedByType)?]

    private let lock = NSLock()

    /// Creates a uniquely indexed collection from an array of uniquely indexed instances.
    /// - Parameter collection: The array of instances to be stored.
    init(_ collection: [any UniquelyIndexedByType]) {
        let highestIndex = collection.map { $0.uniqueIndex }.max() ?? -1
        var storage: [(any UniquelyIndexedByType)?] = Array(repeating: nil, count: highestIndex + 1)
        collection.forEach { storage[$0.uniqueIndex] = $0 }
        self._storage = storage
    }

    /// Gets the element of the collection that matches the passed type.
    /// - Parameter _: The type of the element to be returned
    /// - Returns: The element of the requested type, or `nil` if there is no element of that type.
    func get<T: UniquelyIndexedByType>(_ _: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }
        guard T.uniqueIndex < _storage.count else { return nil }
        return _storage[T.uniqueIndex] as? T
    }

    /// Sets the passed value as the stored value for that type, replacing any previously stored value.
    ///
    /// Use ``clear(_:)`` to remove a stored value.
    /// - Parameter value: The element to be stored in the collection.
    func set<T: UniquelyIndexedByType>(_ value: T) {
        lock.lock()
        defer { lock.unlock() }
        if T.uniqueIndex >= _storage.count {
            let additionalSlots = T.uniqueIndex - _storage.count + 1
            _storage.append(contentsOf: Array(repeating: nil, count: additionalSlots))
        }
        _storage[T.uniqueIndex] = value
    }

    // The members below round out the collection's API but currently have no callers in production
    // code; they are exercised by tests only.  Suppress the analyzer's unused-declaration rule rather
    // than delete them, so the type remains a complete, symmetric collection.
    // swiftlint:disable unused_declaration

    /// Sets the stored value to `nil` for the passed type.
    ///
    /// Capacity in the storage is not added or reduced by this method.
    /// - Parameter type: The type of the element to be set to `nil`.
    func clear<T: UniquelyIndexedByType>(_ type: T.Type) {
        lock.lock()
        defer { lock.unlock() }
        if T.uniqueIndex < _storage.count {
            _storage[T.uniqueIndex] = nil
        }
    }

    /// The number of elements in the collection.
    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return _storage.reduce(0) { $0 + ($1 != nil ? 1 : 0) }
    }

    /// Whether the collection has no elements.
    var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return !_storage.contains { $0 != nil }
    }

    /// All of the elements in the collection, returned in unique index order.
    var allElements: [any UniquelyIndexedByType] {
        lock.lock()
        defer { lock.unlock() }
        return _storage.compactMap { $0 }
    }

    // swiftlint:enable unused_declaration
}
