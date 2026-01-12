//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
import struct Smithy.ShapeID

/// A ``Shape`` subclass specialized for Smithy services.
public class ServiceShape: Shape {
    let operationIDs: [ShapeID]
    let resourceIDs: [ShapeID]
    let errorIDs: [ShapeID]

    public init(
        id: ShapeID,
        traits: [ShapeID: Node],
        operationIDs: [ShapeID],
        resourceIDs: [ShapeID],
        errorIDs: [ShapeID]
    ) {
        self.operationIDs = operationIDs
        self.resourceIDs = resourceIDs
        self.errorIDs = errorIDs
        super.init(id: id, type: .service, traits: traits)
    }

    public var operations: [OperationShape] {
        operationIDs.compactMap { model.shapes[$0] as? OperationShape }
    }

    public var resources: [ResourceShape] {
        resourceIDs.compactMap { model.shapes[$0] as? ResourceShape }
    }

    public var errors: [StructureShape] {
        errorIDs.compactMap { model.shapes[$0] as? StructureShape }
    }

    public var sdkId: String {
        var sdkId = if case .object(let object) = traits[.init("aws.api", "service")],
                       case .string(let sdkId) = object["sdkId"] {
            sdkId
        } else {
            id.name
        }
        let unwantedSuffix = " Service"
        if sdkId.hasSuffix(unwantedSuffix) {
            sdkId.removeLast(unwantedSuffix.count)
        }
        return sdkId
    }

    override func immediateDescendants(includeInput: Bool, includeOutput: Bool) throws -> [Shape] {
        if includeOutput {
            return errors + operations + resources
        } else {
            return operations + resources
        }
    }
}
