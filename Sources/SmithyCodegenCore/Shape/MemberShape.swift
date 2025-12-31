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

    init(id: ShapeID, traits: [ShapeID: Node], targetID: ShapeID) {
        self.targetID = targetID
        super.init(id: id, type: .member, traits: traits)
    }

    public var target: Shape {
        get throws {
            guard let target = model.shapes[targetID] ?? Shape.prelude[targetID] else {
                throw ModelError("Shape \(targetID) does not exist")
            }
            return target
        }
    }

    override var candidates: [Shape] {
        get throws {
            [try target]
        }
    }
}
