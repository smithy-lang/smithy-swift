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
        case moduleName = "module"
        case sdkId
        case internalClient
        case operations
        case modelPath
    }

    public let serviceID: ShapeID
    public let moduleName: String
    public let sdkId: String
    public let internalClient: Bool
    public let operationIDs: [ShapeID]

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let serviceString = try container.decode(String.self, forKey: .serviceID)
        let moduleName = try container.decode(String.self, forKey: .moduleName)
        let sdkId = try container.decode(String.self, forKey: .sdkId)
        let internalClient = try container.decodeIfPresent(Bool.self, forKey: .internalClient) ?? false
        let operations = try container.decodeIfPresent([String].self, forKey: .operations) ?? []

        self.serviceID = try ShapeID(serviceString)
        self.moduleName = moduleName
        self.sdkId = sdkId ?? serviceID.name
        self.internalClient = internalClient
        self.operationIDs = try operations.map(ShapeID.init)
    }

    public var scope: String {
        internalClient ? "package" : "public"
    }

    public var serviceName: String {
        let serviceSuffix = " Service"
        var deserviced = sdkId
        if deserviced.hasSuffix(serviceSuffix) {
            deserviced.removeLast(serviceSuffix.count)
        }
        return deserviced
            .toUpperCamelCase()
            .replacingOccurrences(of: " ", with: "")
    }
}
