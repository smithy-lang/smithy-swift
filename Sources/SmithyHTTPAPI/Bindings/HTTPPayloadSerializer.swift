//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
@_spi(SchemaBasedSerde)
import class Smithy.Schema
import protocol Smithy.SmithyDocument
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.NoOpByDefaultShapeSerializer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.SerializableStruct
@_spi(SchemaBasedSerde)
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeSerializer

@_spi(SchemaBasedSerde)
public final class HTTPPayloadSerializer: NoOpByDefaultShapeSerializer {
    public var data = Data()
    let serializer: any ShapeSerializer

    public init(serializer: any ShapeSerializer) {
        self.serializer = serializer
    }

    public func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        try serializer.writeStruct(schema.target!, value)
        self.data = try serializer.data
    }

    public func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws {
        try serializer.writeDocument(schema.target!, value)
        self.data = try serializer.data
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        self.data = Data(value.utf8)
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        self.data = value
    }
}
