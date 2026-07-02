//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A collection of uniquely indexed values that provides O(1) access to elements.
///
/// Elements are stored in a sparse array of pointers to elements, at their own unique index in the sparse array.
public struct UniquelyIndexedCollection: Sendable {
    private let _storage: [(any UniquelyIndexedByType)?]

    /// Creates a uniquely indexed collection from an array of uniquely indexed instances.
    /// - Parameter collection: The array of instances to be stored.
    public init(_ collection: [any UniquelyIndexedByType]) {
        let highestIndex = collection.map { $0.uniqueIndex }.max() ?? -1
        var storage: [(any UniquelyIndexedByType)?] = Array(repeating: nil, count: highestIndex + 1)
        collection.forEach { storage[$0.uniqueIndex] = $0 }
        self._storage = storage
    }

    /// Gets the element of the collection that matches the passed type.
    /// - Parameter _: The type of the element to be returned
    /// - Returns: The element of the requested type, or `nil` if there is no element of that type.
    public func get<T: UniquelyIndexedByType>(_ _: T.Type) -> T? {
        guard T.uniqueIndex < _storage.count else { return nil }
        return _storage[T.uniqueIndex] as? T
    }

    /// The number of elements in the collection.
    public var count: Int { _storage.count(where: { $0 != nil }) }

    // swiftlint:disable:next empty_count
    public var isEmpty: Bool { count != 0 }

    /// All of the elements in the collection, returned in unique index order.
    public var allElements: [any UniquelyIndexedByType] { _storage.compactMap { $0 } }
}
