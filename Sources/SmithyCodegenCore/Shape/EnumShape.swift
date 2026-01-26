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

/// A ``Shape`` subclass specialized for Smithy enums.
public class EnumShape: Shape, HasMembers {

    public let memberIDs: [ShapeID]

    public init(id: ShapeID, traits: TraitCollection, memberIDs: [ShapeID]) {
        self.memberIDs = memberIDs
        super.init(id: id, type: .enum, traits: traits)
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
