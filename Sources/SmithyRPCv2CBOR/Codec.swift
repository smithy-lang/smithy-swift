//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
@_spi(SchemaBasedSerde)
import class SmithyCBOR.Deserializer
@_spi(SchemaBasedSerde)
import class SmithyCBOR.Serializer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeDeserializer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer

@_spi(SchemaBasedSerde)
public struct Codec: SmithySerialization.Codec {

    public init() {}

    public func makeSerializer() throws -> any ShapeSerializer {
        try Serializer()
    }

    public func makeDeserializer(data: Data) throws -> any ShapeDeserializer {
        try Deserializer(data: data)
    }
}
