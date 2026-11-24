//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// https://smithy.io/2.0/spec/protocol-traits.html#xmlname-trait

@_spi(SchemaBasedSerde)
public final class XMLNameTrait: RuntimeTrait {
    public static var id: ShapeID { .init("smithy.api", "xmlName") }

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public var node: Node { .string(name) }
    public let name: String

    public init(node: Node) throws {
        guard let name = node.string else { throw TraitError("xmlName trait node must contain String") }
        self.name = name
    }

    /// An `xmlName` on a member's target names the target's own XML element, not the member,
    /// so only the member's own trait is applied to a member schema.
    public static func resolvedMemberTrait(member: Node?, target: Node?) throws -> Node? {
        member
    }
}
