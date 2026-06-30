//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A container for traits that allows for type-safe access.
@_spi(SchemaBasedSerde)
public struct TraitCollection: Sendable {
    /// The traits in this collection, as a dictionary of traits keyed by trait shape ID.
    public var traitDict: [ShapeID: any Trait]

    public init() {
        self.traitDict = [:]
    }

    public init(traitDict: [ShapeID: Node], traitTypeDict: [ShapeID: any Trait.Type]) throws {
        let traitPairs: [(ShapeID, any Trait)] = try traitDict.compactMap { shapeID, node in
            guard let TraitType = traitTypeDict[shapeID] else { return nil }
            return (shapeID, try TraitType.init(node: node))
        }
        self.traitDict = Dictionary(uniqueKeysWithValues: traitPairs)
    }

    public init(traits: [any Trait]) {
        self.traitDict = Dictionary(uniqueKeysWithValues: traits.map { ($0.id, $0) })
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
        traitDict[T.id] as? T
    }

    /// Combines two trait collections into a single collection.
    /// - Parameter other: The trait collection to merge.  Traits in this collection overwrite the other.
    /// - Returns: The merged ``TraitCollection``.
    public func adding(_ other: TraitCollection) -> TraitCollection {
        let combined = self.traitDict.merging(other.traitDict) { _, new in new }
        return Self(traits: Array(combined.values))
    }

    /// Returns a trait collection containing only this collection's traits that belong in a schema.
    public var schemaTraits: TraitCollection {
        let schemaTraitDict = traitDict.values.filter { allRuntimeTraitIDs.contains($0.id) }
        return Self(traits: schemaTraitDict)
    }
}

/// Allows for the creation of a ``TraitCollection`` from a `[Trait]` array literal.
extension TraitCollection: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = (any Trait)?

    public init(arrayLiteral elements: ArrayLiteralElement...) {
        self.init(traits: elements.compactMap { $0 })
    }
}

extension TraitCollection: Equatable {

    public static func ==(_ lhs: Self, _ rhs: Self) -> Bool {
        lhs.traitDict.mapValues(\.node) == rhs.traitDict.mapValues(\.node)
    }
}
