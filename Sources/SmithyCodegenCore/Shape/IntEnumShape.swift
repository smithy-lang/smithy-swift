//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID
import enum Smithy.ShapeType

/// A ``Shape`` subclass specialized for Smithy intEnums.
public class IntEnumShape: Shape, HasMembers {
    let memberIDs: [ShapeID]

    public init(id: ShapeID, traits: [ShapeID: Node], memberIDs: [ShapeID]) {
        self.memberIDs = memberIDs
        super.init(id: id, type: .intEnum, traits: traits)
    }

    public var members: [MemberShape] {
        return memberIDs.map { model.shapes[$0]! as! MemberShape }
    }

    override func candidates(for shape: Shape) -> [Shape] {
        members.map { $0.target }
    }
}
