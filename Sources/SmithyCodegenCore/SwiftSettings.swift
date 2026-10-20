//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID

@_spi(SchemaBasedSerde)
public struct SwiftSettings: Sendable, Decodable {

    enum CodingKeys: String, CodingKey {
        case serviceID = "service"
        case internalClient
        case operations
    }

    public let serviceID: ShapeID
    public let internalClient: Bool
    public let operationIDs: [ShapeID]

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let serviceString = try container.decode(String.self, forKey: .serviceID)
        let internalClient = try container.decodeIfPresent(Bool.self, forKey: .internalClient) ?? false
        let operations = try container.decodeIfPresent([String].self, forKey: .operations) ?? []

        self.serviceID = try ShapeID(serviceString)
        self.internalClient = internalClient
        self.operationIDs = try operations.map(ShapeID.init)
    }

    var scope: String {
        internalClient ? "package" : "public"
    }
}
