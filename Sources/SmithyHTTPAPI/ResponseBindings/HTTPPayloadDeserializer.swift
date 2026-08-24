//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import enum Smithy.ByteStream
@_spi(SchemaBasedSerde)
import class Smithy.Schema
import protocol Smithy.SmithyDocument
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.DeserializableStruct
@_spi(SchemaBasedSerde)
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ThrowByDefaultShapeDeserializer
import class SmithyStreams.BufferedStream

/// A deserializer that deserializes non-streaming HTTP payloads.
///
/// Only struct, union, document, string, and blob are currently supported as payload types.
@_spi(SchemaBasedSerde)
public class HTTPPayloadDeserializer: ThrowByDefaultShapeDeserializer {
    let codec: any Codec
    let data: Data

    public init(codec: any Codec, data: Data) {
        self.codec = codec
        self.data = data
    }

    public func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws {
        let payloadDeserializer = try codec.makeDeserializer(data: data)
        try payloadDeserializer.readStruct(schema, &value)
    }

    public func readDocument(_ schema: Schema) throws -> any SmithyDocument {
        let payloadDeserializer = try codec.makeDeserializer(data: data)
        return try payloadDeserializer.readDocument(schema)
    }

    public func readString(_ schema: Schema) throws -> String {
        guard let string = String(data: data, encoding: .utf8) else {
            throw SerializerError("Expected UTF-8 string payload but body is not valid UTF-8")
        }
        return string
    }

    public func readBlob(_ schema: Schema) throws -> Data {
        return data
    }
}
