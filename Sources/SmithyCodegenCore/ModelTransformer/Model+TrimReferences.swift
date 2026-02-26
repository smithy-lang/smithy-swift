//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension Model {

    /// Deletes any references to shapes that have been removed from a model.
    ///
    /// Apply this transform after removing shapes from a model to ensure the model
    /// stays consistent and doesn't include any references to missing shapes.
    ///
    /// This transform will typically be applied within other transforms to make sure
    /// the model is consistent and only references existing shapes after a deletion or
    /// mutation.
    /// - Returns: A model without any references to removed shapes.
    func trimReferences() throws -> Model {
        var trimmedShapes = self.shapes
        var previousTrimmedShapesCount = 0

        // Now remove any members, lists, and maps that refer to nonexistent shapes.
        // We repeat this until no additional shapes are removed to ensure that nested
        // references to nonexistent shapes don't result in an inconsistent model.
        repeat {
            previousTrimmedShapesCount = trimmedShapes.count
            let newTrimmedShapes = try trimmedShapes.filter { (_, shape) in
                switch shape {
                case let listShape as ListShape:
                    // Keep this list if its member's target is present
                    let id = try listShape.member.targetID
                    guard id.namespace != "smithy.api" else { return true }
                    let found = trimmedShapes[id] != nil
                    return found
                case let mapShape as MapShape:
                    // Keep this map if its `value` member's target is present
                    let id = try mapShape.value.targetID
                    guard id.namespace != "smithy.api" else { return true }
                    let found = trimmedShapes[id] != nil
                    return found
                case let memberShape as MemberShape:
                    // Check if this member's target is present, if the target is not in the prelude
                    let targetPresent = if memberShape.targetID.namespace == "smithy.api" {
                        true
                    } else {
                        trimmedShapes[memberShape.targetID] != nil
                    }
                    // Check if this member's container is present
                    let containerPresent = trimmedShapes[memberShape.containerID] != nil

                    // Keep this member if its container and target are both present
                    return targetPresent && containerPresent
                default:
                    return true
                }
            }
            trimmedShapes = newTrimmedShapes
        } while trimmedShapes.count != previousTrimmedShapesCount

        // Finally, go through all the shapes and remove references to removed shapes.
        let finalShapes = trimmedShapes.mapValues { shape -> Shape in
            switch shape {
            case let serviceShape as ServiceShape:
                let operationIDs = serviceShape.operationIDs.filter { trimmedShapes[$0] != nil }
                let resourceIDs = serviceShape.resourceIDs.filter { trimmedShapes[$0] != nil }
                let errorIDs = serviceShape.errorIDs.filter { trimmedShapes[$0] != nil }
                return ServiceShape(
                    id: serviceShape.id,
                    traits: serviceShape.traits,
                    operationIDs: operationIDs,
                    resourceIDs: resourceIDs,
                    errorIDs: errorIDs
                )
            case let resourceShape as ResourceShape:
                let operationIDs = resourceShape.operationIDs.filter { trimmedShapes[$0] != nil }
                let collectionOperationIDs = resourceShape.collectionOperationIDs.filter { trimmedShapes[$0] != nil }
                let resourceIDs = resourceShape.resourceIDs.filter { trimmedShapes[$0] != nil }
                let createID = resourceShape.createID.map { trimmedShapes[$0] != nil ? $0 : nil } ?? nil
                let putID = resourceShape.putID.map { trimmedShapes[$0] != nil ? $0 : nil } ?? nil
                let readID = resourceShape.readID.map { trimmedShapes[$0] != nil ? $0 : nil } ?? nil
                let updateID = resourceShape.updateID.map { trimmedShapes[$0] != nil ? $0 : nil } ?? nil
                let deleteID = resourceShape.deleteID.map { trimmedShapes[$0] != nil ? $0 : nil } ?? nil
                let listID = resourceShape.listID.map { trimmedShapes[$0] != nil ? $0 : nil } ?? nil
                return ResourceShape(
                    id: resourceShape.id,
                    traits: resourceShape.traits,
                    operationIDs: operationIDs,
                    collectionOperationIDs: collectionOperationIDs,
                    resourceIDs: resourceIDs,
                    createID: createID,
                    putID: putID,
                    readID: readID,
                    updateID: updateID,
                    deleteID: deleteID,
                    listID: listID
                )
            case let operationShape as OperationShape:
                let errorIDs = operationShape.errorIDs.filter { trimmedShapes[$0] != nil }
                return OperationShape(
                    id: operationShape.id,
                    traits: operationShape.traits,
                    inputID: operationShape.inputID,
                    outputID: operationShape.outputID,
                    errorIDs: errorIDs
                )
            case let structureShape as StructureShape:
                let memberIDs = structureShape.memberIDs.filter { trimmedShapes[$0] != nil }
                return StructureShape(id: structureShape.id, traits: structureShape.traits, memberIDs: memberIDs)
            case let unionShape as UnionShape:
                let memberIDs = unionShape.memberIDs.filter { trimmedShapes[$0] != nil }
                return UnionShape(id: unionShape.id, traits: unionShape.traits, memberIDs: memberIDs)
            case let enumShape as EnumShape:
                let memberIDs = enumShape.memberIDs.filter { trimmedShapes[$0] != nil }
                return EnumShape(id: enumShape.id, traits: enumShape.traits, memberIDs: memberIDs)
            case let intEnumShape as IntEnumShape:
                let memberIDs = intEnumShape.memberIDs.filter { trimmedShapes[$0] != nil }
                return IntEnumShape(id: intEnumShape.id, traits: intEnumShape.traits, memberIDs: memberIDs)
            default:
                return shape
            }
        }

        // Create the transformed model, and return it to the caller.
        return Model(version: self.version, metadata: self.metadata, shapes: finalShapes)
    }
}
