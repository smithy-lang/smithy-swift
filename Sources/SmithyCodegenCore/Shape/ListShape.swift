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
        // swiftlint:disable:next force_cast
        model.shapes[.init(id: id, member: "member")]! as! MemberShape
    }

    public var members: [MemberShape] {
        [member]
    }

    override var candidates: [Shape] {
        get throws {
            members
        }
    }
}
