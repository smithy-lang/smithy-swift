//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension Model {
    
    /// Reduces the service's operations to those specified in SwiftSettings.
    ///
    /// If SwiftSettings has a null or empty `operations` param, all operations are retained.
    /// - Parameter settings: The SwiftSettings for rendering this service
    /// - Returns: A model with operations as specified by SwiftSettings
    func withOperations(settings: SwiftSettings) throws -> Model {

        // If settings.operations is empty, leave the model unchanged
        guard !settings.operationIDs.isEmpty else { return self }

        // Remove any operation that is not included in the list of operationIDs
        let newShapes = shapes.filter { shapeID, shape in
            guard shape.type == .operation else { return true }
            return settings.operationIDs.contains(shapeID)
        }

        // Create a Model, then trim references to the removed operations
        return try Model(version: version, metadata: metadata, shapes: newShapes).trimReferences()
    }
}
