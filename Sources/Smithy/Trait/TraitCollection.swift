//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A container for traits that allows for type-safe access.
public struct TraitCollection: Sendable, Hashable {
    /// The "raw" traits in this collection, as a dictionary of `Node`s keyed by trait shape ID.
    public var traitDict: [ShapeID: Node]

    public init() {
        self.traitDict = [:]
    }

    public init(traits: [ShapeID: Node]) {
        self.traitDict = traits
    }

    /// Whether the trait collection is empty.
    public var isEmpty: Bool {
        traitDict.isEmpty
    }

    /// The number of traits in the collection.
    public var count: Int {
        traitDict.count
    }

    /// Checks if a trait collection has a trait, by trait type.
    /// - Parameter type: The trait type to be checked.
    /// - Returns: `true` if the collection has a trait for the passed trait, `false` otherwise.
    public func hasTrait<T: Trait>(_ type: T.Type) -> Bool {
        traitDict[T.id] != nil
    }

    /// Checks if a trait collection has a trait, by ID.
    /// - Parameter id: The trait ID to be checked.
    /// - Returns: `true` if the collection has a trait for the passed Shape ID, `false` otherwise.
    public func hasTrait(_ id: ShapeID) -> Bool {
        traitDict[id] != nil
    }

    /// Gets a trait from the collection.
    /// - Parameter type: The trait to be retrieved.
    /// - Returns: The requested trait, or `nil` if the collection doesn't have that trait.
    public func getTrait<T: Trait>(_ type: T.Type) throws -> T? {
        guard let node = traitDict[T.id] else { return nil }
        return try T(node: node)
    }

    /// Adds a new trait to the collection, overwriting an existing, matching trait.
    /// - Parameter trait: The trait to add to the collection.
    public mutating func add(_ trait: Trait) {
        traitDict[trait.id] = trait.node
    }

    /// Combines two trait collections into a single collection.
    /// - Parameter other: The trait collection to merge.  Traits in this collection overwrite the other.
    /// - Returns: The merged ``TraitCollection``.
    public func adding(_ other: TraitCollection) -> TraitCollection {
        let combined = self.traitDict.merging(other.traitDict) { _, new in new }
        return TraitCollection(traits: combined)
    }

    /// Returns a trait collection containing only this collection's traits that belong in a schema.
    public var schemaTraits: TraitCollection {
        let schemaTraitDict = traitDict.filter { (shapeID, _) in allSupportedTraits.contains(shapeID) }
        return Self(traits: schemaTraitDict)
    }
}

/// Allows for the creation of a ``TraitCollection`` from a `[ShapeID: Node]` dictionary literal.
extension TraitCollection: ExpressibleByDictionaryLiteral {
    public typealias Key = ShapeID
    public typealias Value = Node

    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.traitDict = Dictionary(uniqueKeysWithValues: elements)
    }
}

/// Allows for the creation of a ``TraitCollection`` from a `[Trait]` array literal.
extension TraitCollection: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = any Trait

    public init(arrayLiteral elements: ArrayLiteralElement...) {
        self.init(traits: Dictionary(uniqueKeysWithValues: elements.map { ($0.id, $0.node) }))
    }
}
