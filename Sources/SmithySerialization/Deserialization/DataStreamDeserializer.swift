//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import enum Smithy.ByteStream
import protocol Smithy.ResponseMessage
@_spi(SmithyDocumentImpl)
import struct Smithy.StringMapDocument
@_spi(SchemaBasedSerde)
import class Smithy.Schema
import protocol Smithy.SmithyDocument

/// Deserializes a data stream member, i.e. a `blob` with the `@streaming` trait.
@_spi(SchemaBasedSerde)
public struct DataStreamDeserializer: ThrowByDefaultShapeDeserializer {
    let response: any ResponseMessage

    public init(response: any ResponseMessage) {
        self.response = response
    }

    public func readDataStream(_ schema: Schema) throws -> ByteStream {
        response.body
    }
}
