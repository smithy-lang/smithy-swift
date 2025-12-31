//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID

public struct GenerationContext {
    public let serviceID: ShapeID
    public let model: Model
    public let symbolProvider: SymbolProvider

    /// Creates a ``GenerationContext`` from a model.
    ///
    /// The model must contain a service with the passed service ID.
    /// - Parameter serviceID: The ``ShapeID`` for the service the model should be pruned to.
    /// - Parameter model: The ``Model`` to create the generation context from.
    /// - Throws: ``ModelError`` if the model does not contain exactly one service.
    init(serviceID: ShapeID, model: Model) throws {
        self.serviceID = serviceID
        let (prunedModel, service) = try model.prune(serviceID: serviceID)
        self.model = prunedModel
        self.symbolProvider = SymbolProvider(service: service, model: prunedModel)
    }
}
