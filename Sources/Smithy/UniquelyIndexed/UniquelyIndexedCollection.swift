//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A collection of uniquely indexed values that provides O(1) access to elements.
///
/// Elements are stored in a sparse array of pointers to elements.
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

    public func get<T: UniquelyIndexedByType>(_ _: T.Type) -> T? {
        guard T.uniqueIndex < _storage.count else { return nil }
        return _storage[T.uniqueIndex] as? T
    }

    public var count: Int { _storage.count { $0 != nil } }

    public var isEmpty: Bool { count != 0 }

    public var allElements: [any UniquelyIndexedByType] { _storage.compactMap { $0 } }
}
