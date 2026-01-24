//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID
import struct Smithy.TraitCollection

/// A ``Shape`` subclass specialized for Smithy resources.
public class ResourceShape: Shape {
    let operationIDs: [ShapeID]
    let createID: ShapeID?
    let putID: ShapeID?
    let readID: ShapeID?
    let updateID: ShapeID?
    let deleteID: ShapeID?
    let listID: ShapeID?

    init(
        id: ShapeID,
        traits: TraitCollection,
        operationIDs: [ShapeID],
        createID: ShapeID?,
        putID: ShapeID?,
        readID: ShapeID?,
        updateID: ShapeID?,
        deleteID: ShapeID?,
        listID: ShapeID?
    ) {
        self.operationIDs = operationIDs
        self.createID = createID
        self.putID = putID
        self.readID = readID
        self.updateID = updateID
        self.deleteID = deleteID
        self.listID = listID
        super.init(id: id, type: .resource, traits: traits)
    }

    override func immediateDescendants(includeInput: Bool, includeOutput: Bool) throws -> Set<Shape> {
        let allOps = [createID, putID, readID, updateID, deleteID, listID].compactMap { $0 } + operationIDs
        return try Set(allOps.map { try model.expectShape(id: $0) })
    }
}
