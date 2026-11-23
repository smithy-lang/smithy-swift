//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// https://smithy.io/2.0/spec/protocol-traits.html#xmlflattened-trait

@_spi(SchemaBasedSerde)
public final class XMLFlattenedTrait: RuntimeTrait {
    public static var id: ShapeID { .init("smithy.api", "xmlFlattened") }

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public var node: Node { [:] }

    public init(node: Node) throws {}

    /// `xmlFlattened` may only be applied to members, so only the member's trait is used.
    public static func resolvedMemberTrait(member: Node?, target: Node?) throws -> Node? {
        member
    }
}
