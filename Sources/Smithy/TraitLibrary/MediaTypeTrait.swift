//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// https://smithy.io/2.0/spec/protocol-traits.html#mediatype-trait

@_spi(SchemaBasedSerde)
public final class MediaTypeTrait: RuntimeTrait {
    public static var id: ShapeID { .init("smithy.api", "mediaType") }

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public var node: Node { .string(type) }
    public let type: String

    public init(node: Node) throws {
        guard let type = node.string else { throw TraitError("mediaType trait node must contain String") }
        self.type = type
    }
}
