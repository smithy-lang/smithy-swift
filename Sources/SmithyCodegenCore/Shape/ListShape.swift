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
    public let memberIDs: [ShapeID]

    public init(id: ShapeID, traits: TraitCollection, memberIDs: [ShapeID]) {
        self.memberIDs = memberIDs
        super.init(id: id, type: .list, traits: traits)
    }

    public var member: MemberShape {
        get throws {
            // A list will always have one member, and it will always be "member".
            let memberID = memberIDs[0]
            guard memberID.member == "member" else {
                throw ModelError("ListShape does not have expected \"member\" member")
            }
            return try model.expectMemberShape(id: memberID)
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
