//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID

/// A type that provides the resources needed to perform Swift code generation.
public struct GenerationContext {
    public let settings: SwiftSettings
    public let service: ServiceShape
    public let model: Model
    public let symbolProvider: SymbolProvider

    /// Creates a ``GenerationContext`` from a model.
    ///
    /// The model must contain a service with the passed service ID.
    /// - Parameter serviceID: The ``ShapeID`` for the service the model should be pruned to.
    /// - Parameter model: The ``Model`` to create the generation context from.
    /// - Throws: ``ModelError`` if the model does not contain exactly one service.
    init(settings: SwiftSettings, model: Model) throws {

        // Perform model transformations here
        let finalModel = try model
            .withOperations(settings: settings)
            .withSynthesizedInputsOutputs()
            .withDeprecatedShapesRemoved()
            .withUnionsTargetingUnitAdded()
            .optionalizeStructMembers(serviceID: settings.serviceID)
            .prune(serviceID: settings.serviceID)

        // Initialize using the final, processed model
        self.settings = settings
        self.service = try finalModel.expectServiceShape(id: settings.serviceID)
        self.model = finalModel
        self.symbolProvider = SymbolProvider(service: service, model: finalModel)
    }
}
