//
//  File.swift
//  smithy-swift
//
//  Created by Elkins, Josh on 6/30/26.
//

import class Foundation.NSRecursiveLock

@_spi(SchemaBasedSerde)
public class TraitRegistry {
    public static let shared = TraitRegistry()

    private var _counter = 0
    private var _storage = [ShapeID: TraitEntry]()
    private let _lock = NSRecursiveLock()

    private struct TraitEntry {
        let uniqueIndex: Int
        let type: Trait.Type
    }

    private init() {}

    public func register<T: Trait>(_ type: T.Type) -> Int {
        _lock.lock()
        defer { _counter += 1; _lock.unlock() }
        let entry = TraitEntry(uniqueIndex: _counter, type: type)
        _storage[type.id] = entry
        return entry.uniqueIndex
    }

    public func type(_ shapeID: ShapeID) -> (any Trait.Type)? {
        _lock.lock()
        defer { _lock.unlock() }
        return _storage[shapeID]?.type
    }
}
