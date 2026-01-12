//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID
import enum Smithy.ShapeType

/// A ``Shape`` subclass specialized for Smithy structures.
public class StructureShape: Shape, HasMembers {
    let memberIDs: [ShapeID]

    public init(id: ShapeID, traits: [ShapeID: Node], memberIDs: [ShapeID]) {
        self.memberIDs = memberIDs
        super.init(id: id, type: .structure, traits: traits)
    }

    public var members: [MemberShape] {
        get throws {
            try memberIDs.map { memberID in
                guard let shape = model.shapes[memberID] else {
                    throw ModelError("shape does not exist for memberID \(memberID)")
                }
                guard let member = shape as? MemberShape else {
                    throw ModelError("Shape \(memberID) is not a member shape")
                }
                return member
            }
        }
    }

    override func immediateDescendants(includeInput: Bool, includeOutput: Bool) throws -> [Shape] {
        try members
    }
}
