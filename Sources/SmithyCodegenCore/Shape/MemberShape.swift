//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID
import struct Smithy.TraitCollection

/// A ``Shape`` subclass specialized for Smithy members.
public class MemberShape: Shape {
    let targetID: ShapeID

    init(id: ShapeID, traits: TraitCollection, targetID: ShapeID) {
        self.targetID = targetID
        super.init(id: id, type: .member, traits: traits)
    }

    public var container: Shape {
        get throws {
            return try model.expectShape(id: containerID)
        }
    }

    public var containerID: ShapeID { .init(id: id, member: nil) }

    public var target: Shape {
        get throws {
            guard let target = model.shapes[targetID] ?? Shape.prelude[targetID] else {
                throw ModelError("Member \(id): target \(targetID) does not exist")
            }
            return target
        }
    }

    override func immediateDescendants(includeInput: Bool, includeOutput: Bool) throws -> Set<Shape> {
        guard targetID.namespace != "smithy.api" else { return [] }
        return [try target]
    }
}
