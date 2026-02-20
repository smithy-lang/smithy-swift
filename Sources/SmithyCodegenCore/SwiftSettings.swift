//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID

public struct SwiftSettings: Sendable {
    let serviceID: ShapeID
    let sdkId: String
    let `internal`: Bool
    let operationIDs: [ShapeID]

    public init(
        service: String,
        sdkId: String?,
        `internal`: Bool = false,
        operations: [String] = []
    ) throws {
        self.serviceID = try ShapeID(service)
        self.sdkId = sdkId ?? serviceID.name
        self.`internal` = `internal`
        self.operationIDs = try operations.map(ShapeID.init)
    }

    var scope: String {
        `internal` ? "package" : "public"
    }
}
