//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import struct Smithy.Schema
@_spi(SchemaBasedSerde)
import struct Smithy.TimestampFormatTrait
@_spi(SmithyTimestamps) import enum SmithyTimestamps.TimestampFormat

func resolveTimestampFormat(_ schema: Schema) -> TimestampFormat {
    guard let traitFormat = try? schema.getTrait(TimestampFormatTrait.self)?.format else {
        return .dateTime // XML default
    }
    switch traitFormat {
    case .dateTime: return .dateTime
    case .httpDate: return .httpDate
    case .epochSeconds: return .epochSeconds
    }
}
