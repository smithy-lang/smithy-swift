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
    public let traitDict: [ShapeID: any Trait]

    public init() {
        self.traitDict = [:]
    }

    public init(traitDict: [ShapeID: Node], traitTypes: [any Trait.Type]) throws {

        // Index the modeled trait types by ShapeID for lookup
        let traitTypeDict = Dictionary(uniqueKeysWithValues: traitTypes.map { ($0.id, $0) })

        // For each ShapeID & Node in the passed raw trait data, look up the correct modeled
        // trait type by ShapeID, and create the modeled trait instance.
        let traitPairs: [(ShapeID, any Trait)] = try traitDict.compactMap { shapeID, node in
            guard let TraitType = traitTypeDict[shapeID] else { return nil }
            return (shapeID, try TraitType.init(node: node))
        }

        // Finally, convert the ShapeID - modeled Trait pairs into a dictionary.
        self.traitDict = Dictionary(uniqueKeysWithValues: traitPairs)
    }
    
    /// Creates a TraitCollection from an array of modeled Traits.
    /// - Parameter traits: A list of modeled traits to store in this collection.  All traits must be unique by ShapeID.
    public init(traits: [any Trait]) {
        // Convert the modeled Trait list to a dictionary, mapped by trait ShapeID.
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
}

/// Allows for the creation of a ``TraitCollection`` from a `[(any Trait)?]` array literal.
///
/// An array of this type is rendered during schemas codegen as a literal `TraitCollection`.
extension TraitCollection: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = (any Trait)?

    public init(arrayLiteral elements: ArrayLiteralElement...) {
        self.init(traits: elements.compactMap { $0 })
    }
}

extension TraitCollection: Equatable {

    public static func ==(_ lhs: Self, _ rhs: Self) -> Bool {
        // Traits themselves aren't Equatable, but their ShapeID and Node are.
        // Convert the [ShapeID: any Trait] dictionaries to [ShapeID: Node] and compare.
        lhs.traitDict.mapValues(\.node) == rhs.traitDict.mapValues(\.node)
    }
}
