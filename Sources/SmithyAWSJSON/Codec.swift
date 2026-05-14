//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
@_spi(SchemaBasedSerde)
import class SmithyJSON.Deserializer
@_spi(SchemaBasedSerde)
import class SmithyJSON.Serializer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeDeserializer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer

struct Codec: SmithySerialization.Codec {

    func makeSerializer() throws -> any ShapeSerializer {
        SmithyJSON.Serializer()
    }

    func makeDeserializer(data: Data) throws -> any ShapeDeserializer {
        try SmithyJSON.Deserializer(data: data)
    }

}
