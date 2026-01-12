//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID

extension Model {

    // Filters out all shapes except for the identified service and its descendants
    // Returns the pruned model, plus the service shape that it is pruned to
    func prune(serviceID: ShapeID) throws -> (Model, ServiceShape) {

        // Get the service
        let service = try expectServiceShape(id: serviceID)

        // Create a set with the service and its descendants
        let shapesForService = try Set([service]).union(service.descendants)

        // Create a dictionary from the set, keyed by ShapeID
        let shapeDict = Dictionary(uniqueKeysWithValues: shapesForService.map { ($0.id, $0) })

        // Create and return the model & service in a tuple
        let newModel = Model(version: self.version, metadata: self.metadata, shapes: shapeDict)
        return (newModel, service)
    }
}
