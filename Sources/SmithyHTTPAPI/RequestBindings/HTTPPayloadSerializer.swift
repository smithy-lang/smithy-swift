//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import enum Smithy.ByteStream
@_spi(SchemaBasedSerde)
import class Smithy.MediaTypeTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
import enum Smithy.ShapeType
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
    public var data: Data?
    public var mediaType: String?
    private let codec: any Codec

    public init(codec: any Codec, payloadType: ShapeType) {
        self.codec = codec
        switch payloadType {
        case .structure, .union, .document:
            self.data = codec.emptyRequest
            self.mediaType = codec.serializerMediaType
        default:
            self.data = nil
            self.mediaType = nil
        }
    }

    public func writeStruct<S: SerializableStruct>(_ schema: Schema, _ value: S) throws {
        let serializer = try codec.makeSerializer()
        try serializer.writeStruct(schema.target!, value)
        mediaType = serializer.mediaType
        self.data = try serializer.data
    }

    public func writeDocument(_ schema: Schema, _ value: any SmithyDocument) throws {
        let serializer = try codec.makeSerializer()
        try serializer.writeDocument(schema.target!, value)
        mediaType = serializer.mediaType
        self.data = try serializer.data
    }

    public func writeString(_ schema: Schema, _ value: String) throws {
        self.data = Data(value.utf8)
        if let mediaType = schema.getTrait(MediaTypeTrait.self)?.type {
            self.mediaType = mediaType
        } else {
            self.mediaType = "text/plain"
        }
    }

    public func writeBlob(_ schema: Schema, _ value: Data) throws {
        self.data = value
        if let mediaType = schema.getTrait(MediaTypeTrait.self)?.type {
            self.mediaType = mediaType
        } else {
            self.mediaType = "application/octet-stream"
        }
    }
}
