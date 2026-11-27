//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
@_spi(SchemaBasedSerde)
import class SmithyFormURL.Serializer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeDeserializer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer
@_spi(SchemaBasedSerde)
import class SmithyXML.Deserializer

/// awsQuery requests are form URL-encoded, and responses are XML.
struct Codec: SmithySerialization.Codec {

    func makeSerializer() throws -> any ShapeSerializer {
        SmithyFormURL.Serializer(variant: .awsQuery)
    }

    func makeDeserializer(data: Data) throws -> any ShapeDeserializer {
        try SmithyXML.Deserializer(data: data)
    }

    var serializerMediaType: String? { "application/x-www-form-urlencoded" }

    var deserializerMediaType: String? { "text/xml" }
}
