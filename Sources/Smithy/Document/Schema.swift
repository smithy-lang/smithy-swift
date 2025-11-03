//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public class Schema {
    public let id: String
    public let type: ShapeType
    public let traits: [String: Node]
    public let members: [Schema]
    public let memberName: String?
    public let target: Schema?
    public let index: Int

    public init(
        id: String,
        type: ShapeType,
        traits: [String: Node] = [:],
        members: [Schema] = [],
        memberName: String? = nil,
        target: Schema? = nil,
        index: Int = -1
    ) {
        self.id = id
        self.type = type
        self.traits = traits
        self.members = members
        self.memberName = memberName
        self.target = target
        self.index = index
    }
}
