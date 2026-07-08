//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
@_spi(SchemaBasedSerde)
import class Smithy.ServiceTrait
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID
@_spi(SchemaBasedSerde)
import struct Smithy.TraitCollection

/// A ``Shape`` subclass specialized for Smithy services.
@_spi(SchemaBasedSerde)
public class ServiceShape: Shape {
    let operationIDs: [ShapeID]
    let resourceIDs: [ShapeID]
    let errorIDs: [ShapeID]
    let renames: [ShapeID: String]

    public init(
        id: ShapeID,
        traits: TraitCollection,
        operationIDs: [ShapeID],
        resourceIDs: [ShapeID],
        errorIDs: [ShapeID],
        renames: [ShapeID: String]
    ) {
        self.operationIDs = operationIDs
        self.resourceIDs = resourceIDs
        self.errorIDs = errorIDs
        self.renames = renames
        super.init(id: id, type: .service, traits: traits)
    }

    public var operations: [OperationShape] {
        get throws {
            try operationIDs.map { try model.expectOperationShape(id: $0) }
        }
    }

    public var resources: [ResourceShape] {
        get throws {
            try resourceIDs.map { try model.expectResourceShape(id: $0) }
        }
    }

    public var errors: [StructureShape] {
        get throws {
            try errorIDs.map { try model.expectStructureShape(id: $0) }
        }
    }

    public var sdkId: String {
        getTrait(ServiceTrait.self)?.sdkId ?? id.name
    }

    public var sdkIdStrippingService: String {
        get throws {
            var sdkIdStrippingService = sdkId
            let unwantedSuffix = " Service"
            if sdkIdStrippingService.hasSuffix(unwantedSuffix) {
                sdkIdStrippingService.removeLast(unwantedSuffix.count)
            }
            return sdkIdStrippingService
        }
    }

    public var clientBaseName: String {
        get throws {
            try sdkIdStrippingService.toUpperCamelCase()
        }

    }

    override func immediateDescendants(includeInput: Bool, includeOutput: Bool) throws -> Set<Shape> {
        if includeOutput {
            try Set(errors + operations + resources)
        } else {
            try Set(operations + resources)
        }
    }
}
