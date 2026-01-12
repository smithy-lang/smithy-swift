//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID
import enum Smithy.ShapeType

/// A ``Shape`` subclass specialized for Smithy lists.
public class ListShape: Shape, HasMembers {
    let memberIDs: [ShapeID]

    public init(id: ShapeID, traits: [ShapeID: Node], memberIDs: [ShapeID]) {
        self.memberIDs = memberIDs
        super.init(id: id, type: .list, traits: traits)
    }

    public var member: MemberShape {
        get throws {
            try model.expectMemberShape(id: .init(id: id, member: "member"))
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
