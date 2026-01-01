//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID

extension Model {

    func prune(serviceID: ShapeID) throws -> (Model, ServiceShape) {
        // Verify that a service exists for the passed ID
        guard let service = shapes[serviceID] as? ServiceShape else {
            throw ModelError("Service with ID \"\(serviceID)\" does not exist")
        }

        // Filter out only shapes that are the identified service and its descendants
        let shapesForService = try ([service] + service.descendants)
        let shapeDict = Dictionary(uniqueKeysWithValues: shapesForService.map { ($0.id, $0) })
        let newModel = Model(version: self.version, metadata: self.metadata, shapes: shapeDict)
        return (newModel, service)
    }
}
