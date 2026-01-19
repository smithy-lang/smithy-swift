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

/// A ``Shape`` subclass specialized for Smithy maps.
public class MapShape: Shape, HasMembers {
    let memberIDs: [ShapeID]

    public init(id: ShapeID, traits: TraitCollection, memberIDs: [ShapeID]) {
        self.memberIDs = memberIDs
        super.init(id: id, type: .map, traits: traits)
    }

    public var keyID: ShapeID { .init(id: self.id, member: "key") }

    public var key: MemberShape {
        get throws {
            try model.expectMemberShape(id: keyID)
        }
    }

    public var valueID: ShapeID { .init(id: self.id, member: "value") }

    public var value: MemberShape {
        get throws {
            try model.expectMemberShape(id: valueID)
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
