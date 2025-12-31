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
        let shapeIDsForService = try ([service] + service.descendants).map { $0.id }
        let shapesForService = shapes.filter { shapeIDsForService.contains($0.key) }
        let newModel = Model(version: self.version, metadata: self.metadata, shapes: shapesForService)
        return (newModel, service)
    }
}
