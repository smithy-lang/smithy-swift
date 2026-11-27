//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// https://smithy.io/2.0/spec/protocol-traits.html#xmlnamespace-trait

@_spi(SchemaBasedSerde)
public final class XMLNamespaceTrait: RuntimeTrait {
    public static var id: ShapeID { .init("smithy.api", "xmlNamespace") }

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public let node: Node

    /// The namespace URI.
    public let uri: String

    /// The namespace prefix, or `nil` for the default namespace.
    public let prefix: String?

    public init(node: Node) throws {
        guard case .object(let object) = node else {
            throw TraitError("xmlNamespace trait does not have root object")
        }
        guard let uri = object["uri"]?.string else {
            throw TraitError("xmlNamespace trait does not have uri")
        }
        self.node = node
        self.uri = uri
        self.prefix = object["prefix"]?.string
    }

    /// An `xmlNamespace` on a member's target applies to the target's own XML element, not the member's,
    /// so only the member's own trait is applied to a member schema.
    public static func resolvedMemberTrait(member: Node?, target: Node?) throws -> Node? {
        member
    }
}
