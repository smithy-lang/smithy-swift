//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct EnumTrait: Trait {

    public struct EnumMember {
        public let value: String
        public let name: String?
    }
    public static var id: ShapeID { .init("smithy.api", "enum") }

    public let node: Node
    public let members: [EnumMember]

    public init(node: Node) throws {
        guard let list = node.list else {
            throw TraitError("EnumTrait root node is not .list")
        }
        let members = try list.map { element in
            guard let member = element.object else {
                throw TraitError("EnumTrait member is not .object")
            }
            guard let valueNode = member["value"] else {
                throw TraitError("EnumTrait member does not have value field")
            }
            guard let value = valueNode.string else {
                throw TraitError("EnumTrait member does not have string for value")
            }
            return EnumMember(value: value, name: member["name"]?.string)
        }
        self.node = node
        self.members = members
    }
}
