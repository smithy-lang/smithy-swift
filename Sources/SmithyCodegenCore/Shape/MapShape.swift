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
        model.shapes[.init(id: id, member: "key")]! as! MemberShape
    }

    public var value: MemberShape {
        model.shapes[.init(id: id, member: "value")]! as! MemberShape
    }

    public var members: [MemberShape] {
        return [key, value]
    }

    override func candidates(for shape: Shape) -> [Shape] {
        members.map { $0.target }
    }
}
