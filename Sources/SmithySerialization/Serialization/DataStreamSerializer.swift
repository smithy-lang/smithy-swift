//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.RequestMessageBuilder
import enum Smithy.ByteStream
@_spi(SchemaBasedSerde)
import class Smithy.MediaTypeTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import class Smithy.StreamingTrait

@_spi(SchemaBasedSerde)
public class DataStreamSerializer: NoOpByDefaultShapeSerializer {
    public var body: ByteStream = .noStream
    public var mediaType: String? = "application/octet-stream"

    public init() {}

    public func writeDataStream(_ schema: Schema, _ value: ByteStream) throws {
        guard schema.hasTrait(StreamingTrait.self) else { return }
        self.body = value
        if let mediaType = schema.getTrait(MediaTypeTrait.self)?.type {
            self.mediaType = mediaType
        }
    }
}
