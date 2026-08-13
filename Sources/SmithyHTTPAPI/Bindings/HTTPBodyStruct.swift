//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.SerializableStruct
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer

struct HTTPRequestBodyProxy<Input: SerializableStruct>: SerializableStruct {
    let bindings: [HTTPBinding]
    let input: Input

    func serializeMembers(_ schema: Schema, _ serializer: any ShapeSerializer) throws {
        // Serializes members with an intercepting serializer that does not serialize members
        // that aren't bound to the HTTP body.
        let httpBodySerializer = try HTTPBodySerializer(serializer: serializer, bindings: self.bindings)
        try self.input.serializeMembers(schema, httpBodySerializer)
    }

    func serialize(_ serializer: any ShapeSerializer) throws {
        try self.input.serialize(serializer)
    }
}
