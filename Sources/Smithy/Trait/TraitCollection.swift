//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct TraitCollection: Sendable, Hashable {
    public var traitDict: [ShapeID: Node]

    public init() {
        self.traitDict = [:]
    }

    public init(traits: [ShapeID: Node]) {
        self.traitDict = traits
    }

    public var isEmpty: Bool {
        traitDict.isEmpty
    }

    public var count: Int {
        traitDict.count
    }

    public func hasTrait<T: Trait>(_ type: T.Type) -> Bool {
        traitDict[T.id] != nil
    }

    public func hasTrait(_ id: ShapeID) -> Bool {
        traitDict[id] != nil
    }

    public func getTrait<T: Trait>(_ type: T.Type) throws -> T? {
        guard let node = traitDict[T.id] else { return nil }
        return try T(node: node)
    }

    public mutating func add(_ trait: Trait) {
        traitDict[trait.id] = trait.node
    }

    public func adding(_ other: TraitCollection) -> TraitCollection {
        let combined = self.traitDict.merging(other.traitDict) { _, new in new }
        return TraitCollection(traits: combined)
    }
}

extension TraitCollection: ExpressibleByDictionaryLiteral {
    public typealias Key = ShapeID
    public typealias Value = Node

    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.traitDict = Dictionary(uniqueKeysWithValues: elements)
    }
}

extension TraitCollection: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = any Trait

    public init(arrayLiteral elements: ArrayLiteralElement...) {
        self.init(traits: Dictionary(uniqueKeysWithValues: elements.map { ($0.id, $0.node) }))
    }
}
