//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
@_spi(SchemaBasedSerde)
import SmithyJSON
@_spi(SchemaBasedSerde)
import SmithySerialization

// TestCodec uses JSON to serialize struct/union/document payloads.  This allows for the easiest,
// simplest verification of test cases.
//
// Other serialization formats may be used with HTTP bindings as well.
struct TestCodec: Codec {

    func makeSerializer() throws -> any ShapeSerializer {
        SmithyJSON.Serializer(usesJSONNameTrait: false)
    }

    func makeDeserializer(data: Data) throws -> any ShapeDeserializer {
        try SmithyJSON.Deserializer(usesJSONNameTrait: false, data: data)
    }

    var emptyRequest: Data? { Data("{}".utf8) }

    var emptyResponse: Data? { Data("{}".utf8) }

    var serializerMediaType: String? { "application/json" }

    var deserializerMediaType: String? { "application/json" }
}
