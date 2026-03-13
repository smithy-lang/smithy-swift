//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID

extension Model {

    /// Filters out all shapes except for the identified service and its direct & indirect descendants.
    ///
    /// This eliminates any shapes in the model that are not needed for the service being generated.
    /// - Parameter serviceID: The ShapeID for the service that is being generated.
    /// - Returns: The transformed model.
    func prune(serviceID: ShapeID) throws -> Model {

        // Get the service
        let service = try expectServiceShape(id: serviceID)

        // Create a set with the service and its descendants
        let shapesForService = try Set([service]).union(service.descendants)

        // Create a dictionary from the set, keyed by ShapeID
        let shapeDict = Dictionary(uniqueKeysWithValues: shapesForService.map { ($0.id, $0) })

        // Create and return the transformed model
        return Model(version: self.version, metadata: self.metadata, shapes: shapeDict)
    }
}
