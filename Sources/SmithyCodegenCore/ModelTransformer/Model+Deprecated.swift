//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Foundation.DateFormatter
import struct Foundation.Locale

extension Model {
    
    /// Removes all shapes with the `deprecated` trait and a `since` date after `2024-09-17`, the `aws-sdk-swift`
    /// GA date.
    /// - Returns: The transformed model.
    func withDeprecatedShapesRemoved() throws -> Model {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        // The "cutoff date".  Shapes deprecated before this date will be removed from the model.
        let cutoff = formatter.date(from: "2024-09-17")!

        // Filter the deprecated shapes from the model.
        let nonDeprecatedShapes = try shapes.filter { (_, shape) in

            // Keep this shape if it doesn't have a DeprecatedTrait with a `since` value.
            guard let since = try shape.getTrait(DeprecatedTrait.self)?.since else { return true }

            // Keep this shape if the `since` value doesn't parse to a yyyy-MM-dd date.
            guard let sinceDate = formatter.date(from: since) else { return true }

            // Compare dates, keep the shape if it was deprecated before the cutoff.
            return sinceDate > cutoff
        }

        var trimmedShapes = nonDeprecatedShapes
        var previousTrimmedShapesCount = 0

        // Now remove any members, lists, and maps that refer to deprecated shapes.
        // We repeat this until no additional shapes are removed to ensure that nested
        // references to deprecated shapes don't result in an inconsistent model.
        repeat {
            previousTrimmedShapesCount = trimmedShapes.count
            let newTrimmedShapes = try trimmedShapes.filter { (_, shape) in
                switch shape {
                case let listShape as ListShape:
                    let id = try listShape.member.targetID
                    guard id.namespace != "smithy.api" else { return true }
                    let found = trimmedShapes[id] != nil
                    return found
                case let mapShape as MapShape:
                    let id = try mapShape.value.targetID
                    guard id.namespace != "smithy.api" else { return true }
                    let found = trimmedShapes[id] != nil
                    return found
                case let memberShape as MemberShape:
                    let id = memberShape.targetID
                    guard id.namespace != "smithy.api" else { return true }
                    let found = trimmedShapes[id] != nil
                    return found
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
