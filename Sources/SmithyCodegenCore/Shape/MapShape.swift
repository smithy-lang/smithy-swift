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
            // A map will always have two members, and the first will always be "key".
            let keyID = memberIDs[0]
            guard keyID.member == "key" else {
                throw ModelError("MapShape does not have expected Key member")
            }
            return try model.expectMemberShape(id: keyID)
        }
    }

    public var valueID: ShapeID { .init(id: self.id, member: "value") }

    public var value: MemberShape {
        get throws {
            // A map will always have two members, and the second will always be "value".
            let valueID = memberIDs[1]
            guard valueID.member == "value" else {
                throw ModelError("MapShape does not have expected Value member")
            }
            return try model.expectMemberShape(id: valueID)
        }
    }

    public var members: [MemberShape] {
        get throws {
            try memberIDs.map { try model.expectMemberShape(id: $0) }
        }
    }

    override func immediateDescendants(includeInput: Bool, includeOutput: Bool) throws -> Set<Shape> {
        try Set(members)
    }
}
