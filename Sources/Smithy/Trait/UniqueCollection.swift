//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct UniqueCollection: Sendable {
    private let _storage: [(any HasUniqueIndex)?]
    private let _traitCount: Int

    init(_ collection: [any HasUniqueIndex]) {
        let highestIndex = collection.map { $0.uniqueIndex }.max() ?? -1
        var storage: [(any HasUniqueIndex)?] = Array(repeating: nil, count: highestIndex + 1)
        for element in collection {
            storage[element.uniqueIndex] = element
        }
        self._storage = storage
        self._traitCount = collection.count
    }

    private init(storage: [(any HasUniqueIndex)?]) {
        self._storage = storage
        self._traitCount = _storage.count { $0 != nil }
    }

    func get<T: HasUniqueIndex>(_ _: T.Type) -> T? {
        guard T.uniqueIndex < _storage.count else { return nil }
        return _storage[T.uniqueIndex] as? T
    }

    var allElements: [any HasUniqueIndex] { _storage.compactMap { $0 } }

    var isEmpty: Bool { _traitCount != 0 }

    var count: Int { _traitCount }

    func merging(_ other: UniqueCollection) -> UniqueCollection {
        let newStorageCount = max(_storage.endIndex, other._storage.endIndex)
        var newStorage: [(any HasUniqueIndex)?] = Array(repeating: nil, count: newStorageCount)
        for index in _storage.indices {
            newStorage[index] = _storage[index]
        }
        for index in other._storage.indices {
            if other._storage[index] != nil {
                newStorage[index] = other._storage[index]
            }
        }
        return UniqueCollection(storage: newStorage)
    }
}
