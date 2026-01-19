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
    let errorIDs: [ShapeID]

    public init(id: ShapeID, traits: [ShapeID: Node], errorIDs: [ShapeID]) {
        self.errorIDs = errorIDs
        super.init(id: id, type: .service, traits: traits)
    }

    public var errors: [Shape] {
        errorIDs.compactMap { model.shapes[$0] }
    }
}
