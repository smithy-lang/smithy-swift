//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A synthetic trait that records the shape ID an operation input or output had in the model, before it
/// was replaced with a synthesized structure for code generation.
///
/// Protocols that serialize the name of the input structure, i.e. `restXml`, which names the root element
/// of a request body for the input shape, use it to recover the modeled name.
///
/// This trait is applied using a model transform, prior to code generation.
@_spi(SchemaBasedSerde)
public final class OriginalShapeIDTrait: RuntimeTrait {
    public static var id: ShapeID { .init("swift.synthetic", "originalShapeID") }

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public var node: Node { .string(originalID.absolute) }

    /// The shape ID of the input or output as modeled.
    public let originalID: ShapeID

    public init(node: Node) throws {
        guard let string = node.string else { throw TraitError("originalShapeID trait node must contain String") }
        self.originalID = try ShapeID(string)
    }

    public init(originalID: ShapeID) {
        self.originalID = originalID
    }
}
