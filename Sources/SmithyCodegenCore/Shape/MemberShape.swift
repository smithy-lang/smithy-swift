//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID

/// A ``Shape`` subclass specialized for Smithy members.
public class MemberShape: Shape {
    let targetID: ShapeID

    init(id: ShapeID, traits: [ShapeID : Node], targetID: ShapeID) {
        self.targetID = targetID
        super.init(id: id, type: .member, traits: traits)
    }

    public var target: Shape {
        return model.shapes[targetID] ?? Shape.prelude[targetID]!
    }
}
