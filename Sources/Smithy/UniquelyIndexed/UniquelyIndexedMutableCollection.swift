//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Atomics.AtomicReference
import class Atomics.ManagedAtomic

/// A mutable collection of uniquely indexed values that provides O(1) access to elements.
///
/// Elements are stored in a sparse array of pointers to elements, at their own unique index in the sparse array.
///
/// The storage array is immutable once published, and is replaced wholesale on mutation by an atomic
/// compare-exchange.  Readers therefore never block and never acquire a lock; they take one atomic load
/// of the current storage.  This matters because this type is on the serialization hot path and, in its
/// only production use (a ``Schema``'s extensions), is written a handful of times during warmup and read
/// on every subsequent access.
final class UniquelyIndexedMutableCollection: @unchecked Sendable {

    /// An immutable snapshot of the collection's storage.
    ///
    /// Wrapping the array in a class lets it be swapped atomically as a single reference.
    private final class Storage: AtomicReference {
        let elements: [(any UniquelyIndexedByType)?]

        init(_ elements: [(any UniquelyIndexedByType)?]) {
            self.elements = elements
        }
    }

    /// The current storage snapshot.  Replaced, never mutated in place.
    private let _storage: ManagedAtomic<Storage>

    /// Creates a uniquely indexed collection from an array of uniquely indexed instances.
    /// - Parameter collection: The array of instances to be stored.
    init(_ collection: [any UniquelyIndexedByType]) {
        let highestIndex = collection.map { $0.uniqueIndex }.max() ?? -1
        var elements: [(any UniquelyIndexedByType)?] = Array(repeating: nil, count: highestIndex + 1)
        collection.forEach { elements[$0.uniqueIndex] = $0 }
        self._storage = ManagedAtomic(Storage(elements))
    }

    /// Gets the element of the collection that matches the passed type.
    /// - Parameter _: The type of the element to be returned
    /// - Returns: The element of the requested type, or `nil` if there is no element of that type.
    func get<T: UniquelyIndexedByType>(_ _: T.Type) -> T? {
        let elements = _storage.load(ordering: .acquiring).elements
        guard T.uniqueIndex < elements.count else { return nil }
        return elements[T.uniqueIndex] as? T
    }

    /// Sets the passed value as the stored value for that type, replacing any previously stored value.
    ///
    /// Use ``clear(_:)`` to remove a stored value.
    /// - Parameter value: The element to be stored in the collection.
    func set<T: UniquelyIndexedByType>(_ value: T) {
        update { elements in
            if T.uniqueIndex >= elements.count {
                let additionalSlots = T.uniqueIndex - elements.count + 1
                elements.append(contentsOf: Array(repeating: nil, count: additionalSlots))
            }
            elements[T.uniqueIndex] = value
        }
    }

    /// Replaces the storage with a snapshot produced by applying `mutation` to the current one.
    ///
    /// Retries on lost races, so a concurrent write to a different index is never dropped.
    /// - Parameter mutation: A closure that edits a copy of the current storage in place.
    private func update(_ mutation: (inout [(any UniquelyIndexedByType)?]) -> Void) {
        var current = _storage.load(ordering: .acquiring)
        while true {
            var elements = current.elements
            mutation(&elements)
            let (exchanged, original) = _storage.compareExchange(
                expected: current,
                desired: Storage(elements),
                ordering: .acquiringAndReleasing
            )
            if exchanged { return }
            current = original
        }
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
        update { elements in
            if T.uniqueIndex < elements.count {
                elements[T.uniqueIndex] = nil
            }
        }
    }

    /// The number of elements in the collection.
    var count: Int {
        _storage.load(ordering: .acquiring).elements.reduce(0) { $0 + ($1 != nil ? 1 : 0) }
    }

    /// Whether the collection has no elements.
    var isEmpty: Bool {
        !_storage.load(ordering: .acquiring).elements.contains { $0 != nil }
    }

    /// All of the elements in the collection, returned in unique index order.
    var allElements: [any UniquelyIndexedByType] {
        _storage.load(ordering: .acquiring).elements.compactMap { $0 }
    }

    // swiftlint:enable unused_declaration
}
