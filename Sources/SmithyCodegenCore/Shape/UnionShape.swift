//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID
import enum Smithy.ShapeType

/// A ``Shape`` subclass specialized for Smithy unions.
public class UnionShape: Shape, HasMembers {
    let memberIDs: [ShapeID]

    public init(id: ShapeID, traits: [ShapeID: Node], memberIDs: [ShapeID]) {
        self.memberIDs = memberIDs
        super.init(id: id, type: .union, traits: traits)
    }

    public var members: [MemberShape] {
        return memberIDs.map { model.shapes[$0]! as! MemberShape } // swiftlint:disable:this force_cast
    }

    override var candidates: [Shape] {
        get throws {
            members
        }
    }
}
