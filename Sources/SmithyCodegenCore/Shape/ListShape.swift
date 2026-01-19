//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID
import enum Smithy.ShapeType
import struct Smithy.TraitCollection

/// A ``Shape`` subclass specialized for Smithy lists.
public class ListShape: Shape, HasMembers {
    let memberIDs: [ShapeID]

    public init(id: ShapeID, traits: TraitCollection, memberIDs: [ShapeID]) {
        self.memberIDs = memberIDs
        super.init(id: id, type: .list, traits: traits)
    }

    public var memberID: ShapeID { .init(id: self.id, member: "member") }

    public var member: MemberShape {
        get throws {
            try model.expectMemberShape(id: memberID)
        }
    }

    public var members: [MemberShape] {
        get throws {
            try [member]
        }
    }

    override func immediateDescendants(includeInput: Bool, includeOutput: Bool) throws -> Set<Shape> {
        try Set(members)
    }
}
