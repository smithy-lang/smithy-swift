//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A container for traits that allows for type-safe access.
@_spi(SchemaBasedSerde)
public struct TraitCollection: Sendable {
    private let uniqueCollection: UniqueCollection

    public init() {
        self.uniqueCollection = UniqueCollection([])
    }

    public init(traitMap: [ShapeID: Node] = [:]) throws {
        let traits = try traitMap.compactMap { try trait(id: $0.key, node: $0.value) }
        self.init(traits: traits)
    }

    public init(traits: [any Trait]) {
        self.uniqueCollection = UniqueCollection(traits)
    }

    private init(uniqueCollection: UniqueCollection) {
        self.uniqueCollection = uniqueCollection
    }

    public var traitDict: [ShapeID: Node] {
        let allTraits = uniqueCollection.allElements as? [any Trait] ?? []
        return Dictionary(uniqueKeysWithValues: allTraits.map { ($0.id, $0.node) })
    }

    /// Whether the trait collection is empty.
    public var isEmpty: Bool {
        uniqueCollection.isEmpty
    }

    /// The number of traits in the collection.
    public var count: Int {
        uniqueCollection.count
    }

    /// Checks if a trait collection has a trait, by trait type.
    /// - Parameter type: The trait type to be checked.
    /// - Returns: `true` if the collection has a trait for the passed trait, `false` otherwise.
    public func hasTrait<T: Trait>(_ type: T.Type) -> Bool {
        uniqueCollection.get(T.self) != nil
    }

    /// Checks if a trait collection has a trait, by ID.
    /// - Parameter id: The trait ID to be checked.
    /// - Returns: `true` if the collection has a trait for the passed Shape ID, `false` otherwise.
    public func hasTrait(_ id: ShapeID) -> Bool {
        guard let TraitType = allSupportedTraitTypes[id] else { return false }
        return uniqueCollection.get(TraitType.self) != nil
    }

    /// Gets a trait from the collection.
    /// - Parameter type: The trait to be retrieved.
    /// - Returns: The requested trait, or `nil` if the collection doesn't have that trait.
    public func getTrait<T: Trait>(_ type: T.Type) throws -> T? {
        uniqueCollection.get(T.self)
    }

    /// Combines two trait collections into a single collection.
    /// - Parameter other: The trait collection to merge.  Traits in this collection overwrite the other.
    /// - Returns: The merged ``TraitCollection``.
    public func adding(_ other: TraitCollection) -> TraitCollection {
        let combined = self.uniqueCollection.merging(other.uniqueCollection)
        return TraitCollection(uniqueCollection: combined)
    }

    /// Returns a trait collection containing only this collection's traits that belong in a schema.
    public var schemaTraits: TraitCollection {
        let schemaTraitDict = uniqueCollection
            .allElements
            .map { $0 as! any Trait }
            .filter { allSupportedTraitIDs.contains($0.id) }
        return Self(traits: schemaTraitDict)
    }
}

/// Allows for the creation of a ``TraitCollection`` from a `[ShapeID: Node]` dictionary literal.
extension TraitCollection: ExpressibleByDictionaryLiteral {
    public typealias Key = ShapeID
    public typealias Value = Node

    public init(dictionaryLiteral elements: (Key, Value)...) {
        try! self.init(traitMap: Dictionary(uniqueKeysWithValues: elements))
    }
}

/// Allows for the creation of a ``TraitCollection`` from a `[Trait]` array literal.
extension TraitCollection: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = any Trait

    public init(arrayLiteral elements: ArrayLiteralElement...) {
        try! self.init(traitMap: Dictionary(uniqueKeysWithValues: elements.map { ($0.id, $0.node) }))
    }
}

func trait(id: ShapeID, node: Node) throws -> (any Trait)? {
    guard let TraitType = allSupportedTraitTypes[id] else { return nil }
    return try TraitType.init(node: node)
}
