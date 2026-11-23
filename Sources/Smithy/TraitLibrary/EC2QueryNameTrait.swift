//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// https://smithy.io/2.0/aws/protocols/aws-ec2-query-protocol.html#aws-protocols-ec2queryname-trait

@_spi(SchemaBasedSerde)
public final class EC2QueryNameTrait: RuntimeTrait {
    public static var id: ShapeID { .init("aws.protocols", "ec2QueryName") }

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public var node: Node { .string(name) }
    public let name: String

    public init(node: Node) throws {
        guard let name = node.string else { throw TraitError("ec2QueryName trait node must contain String") }
        self.name = name
    }

    /// `ec2QueryName` may only be applied to members, so only the member's trait is used.
    public static func resolvedMemberTrait(member: Node?, target: Node?) throws -> Node? {
        member
    }
}
