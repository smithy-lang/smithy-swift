//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.SmithyDocument
@_spi(SmithyNodeImpl) import enum Smithy.Node
@_spi(SmithyTimestamps) import SmithyTimestamps

extension SchemaProtocol {

    public var jsonName: String? {
        traits["smithy.api#jsonName"]?.string
    }

    public var enumValue: (any SmithyDocument)? {
        traits["smithy.api#enumValue"]?.toDocument()
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
        guard let timestampFormatString = traits["smithy.api#timestampFormat"]?.string else { return nil }
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
        traits["smithy.api#default"]?.toDocument()
    }
}
