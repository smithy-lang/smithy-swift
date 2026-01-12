//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID
import enum Smithy.ShapeType

/// A ``Shape`` subclass specialized for Smithy maps.
public class MapShape: Shape, HasMembers {
    let memberIDs: [ShapeID]

    public init(id: ShapeID, traits: [ShapeID: Node], memberIDs: [ShapeID]) {
        self.memberIDs = memberIDs
        super.init(id: id, type: .map, traits: traits)
    }

    public var key: MemberShape {
        get throws {
            try model.expectMemberShape(id: .init(id: id, member: "key"))
        }
    }

    public var value: MemberShape {
        get throws {
            try model.expectMemberShape(id: .init(id: id, member: "value"))
        }
    }

    public var members: [MemberShape] {
        get throws {
            try [key, value]
        }
    }

    override func immediateDescendants(includeInput: Bool, includeOutput: Bool) throws -> Set<Shape> {
        try Set(members)
    }
}
