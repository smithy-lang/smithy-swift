//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A container for traits that allows for type-safe access.
@_spi(SchemaBasedSerde)
public struct TraitCollection: Sendable {
    /// The traits in this collection, stored in a uniquely indexed collection for O(1) access.
    public let collection: UniquelyIndexedCollection

    public init() {
        self.collection = UniquelyIndexedCollection([])
    }

    public init(traitDict: [ShapeID: Node], traitTypes: [any Trait.Type]) throws {
        // Index the modeled trait types by ShapeID for lookup
        let traitTypeDict = Dictionary(uniqueKeysWithValues: traitTypes.map { ($0.id, $0) })

        // For each ShapeID & Node in the passed raw trait data, look up the correct modeled
        // trait type by ShapeID, and create the modeled trait instance.
        // Traits that aren't modeled in traitTypes will be excluded.
        let traits: [any Trait] = try traitDict.compactMap { shapeID, node in
            guard let TraitType = traitTypeDict[shapeID] else { return nil }
            return try TraitType.init(node: node)
        }
        self.collection = UniquelyIndexedCollection(traits)
    }

    /// Creates a TraitCollection from an array of modeled Traits.
    /// - Parameter traits: A list of modeled traits to store in this collection.  All traits must be unique by ShapeID.
    public init(traits: [any Trait]) {
        // Convert the modeled Trait list to a dictionary, mapped by trait ShapeID.
        self.collection = UniquelyIndexedCollection(traits)
    }

    /// Whether the trait collection is empty.
    public var isEmpty: Bool {
        self.collection.isEmpty
    }

    /// The number of traits in the collection.
    public var count: Int {
        self.collection.count
    }

    /// Checks if a trait collection has a trait, by trait type.
    /// - Parameter type: The trait type to be checked.
    /// - Returns: `true` if the collection has a trait for the passed trait, `false` otherwise.
    public func hasTrait<T: Trait>(_ type: T.Type) -> Bool {
        collection.get(T.self) != nil
    }

    /// Gets a trait from the collection.
    /// - Parameter type: The trait to be retrieved.
    /// - Returns: The requested trait, or `nil` if the collection doesn't have that trait.
    public func getTrait<T: Trait>(_ type: T.Type) -> T? {
        collection.get(T.self)
    }

    /// Combines two trait collections into a single collection.
    /// - Parameter other: The trait collection to merge.  Traits in this collection overwrite the other.
    /// - Returns: The merged ``TraitCollection``.
    public func adding(_ other: TraitCollection) -> TraitCollection {
        return Self(
            traits: (self.collection.allElements as! [any Trait]) + (other.collection.allElements as! [any Trait])
        )
    }

    public var traitDict: [ShapeID: any Trait] {
        let traits = collection.allElements as! [any Trait]
        return Dictionary(uniqueKeysWithValues: traits.map { ($0.id, $0) })
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
        // Convert the [any Trait] arrays to [ShapeID] and [Node] and compare.
        guard let lhsTraits = lhs.collection.allElements as? [any Trait] else { return false }
        guard let rhsTraits = rhs.collection.allElements as? [any Trait] else { return false }
        return lhsTraits.map { $0.id } == rhsTraits.map { $0.id } &&
            lhsTraits.map { $0.node } == rhsTraits.map { $0.node }
    }
}
