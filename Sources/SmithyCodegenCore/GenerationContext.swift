//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct GenerationContext {
    public let service: ServiceShape
    public let model: Model
    public let symbolProvider: SymbolProvider
    
    /// Creates a ``GenerationContext`` from a model.
    ///
    /// The model must contain exactly one service.
    /// - Parameter model: The ``Model`` to create the generation context from.
    /// - Throws: ``ModelError`` if the model does not contain exactly one service.
    init(model: Model) throws {
        let services = model.shapes.values.filter { $0.type == .service }
        guard services.count == 1, let service = services.first as? ServiceShape else {
            throw ModelError("Model contains \(services.count) services")
        }
        self.service = service
        self.model = model
        self.symbolProvider = SymbolProvider(service: service, model: model)
    }
}
