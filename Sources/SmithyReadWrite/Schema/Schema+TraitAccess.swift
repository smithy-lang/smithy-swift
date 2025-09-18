//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.SmithyDocument
@_spi(SmithyDocumentImpl) import struct Smithy.StringDocument
@_spi(SmithyDocumentImpl) import struct Smithy.IntegerDocument
@_spi(SmithyTimestamps) import SmithyTimestamps

extension SchemaProtocol {

    public var jsonName: String? {
        guard let jsonNameTrait = traits["smithy.api#jsonName"] else { return nil }
        guard case .string(let jsonName) = jsonNameTrait else { return nil }
        return jsonName
    }

    public var enumValue: (any SmithyDocument)? {
        guard let enumValueTrait = traits["smithy.api#enumValue"] else { return nil }
        switch enumValueTrait {
        case .string(let value):
            return StringDocument(value: value)
        case .number(let value):
            return IntegerDocument(value: Int(value.rounded(.toNearestOrAwayFromZero)))
        default:
            fatalError("Unexpected enum value")
        }
    }

    public var isSparse: Bool {
        traits.contains { $0.key == "smithy.api#sparse" }
    }

    public var isRequired: Bool {
        traits.contains { $0.key == "smithy.api#required" }
    }

    public var httpPayload: Bool {
        traits.contains { $0.key == "smithy.api#httpPayload" }
    }

    public var timestampFormat: SmithyTimestamps.TimestampFormat? {
        guard let timestampFormatTrait = traits["smithy.api#timestampFormat"] else { return nil }
        guard case .string(let timestampFormatString) = timestampFormatTrait else { return nil }
        switch timestampFormatString {
        case "date-time":
            return .dateTime
        case "epoch-seconds":
            return .epochSeconds
        case "http-date":
            return .httpDate
        default:
            fatalError("Unexpected value for timestamp format")
        }
    }

    public var defaultValue: (any Smithy.SmithyDocument)? {
        guard let defaultValueTrait = traits["smithy.api#default"] else { return nil }
        return defaultValueTrait.toDocument()
    }
}
