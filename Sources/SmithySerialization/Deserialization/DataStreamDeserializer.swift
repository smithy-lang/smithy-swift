//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.ByteStream
import protocol Smithy.ResponseMessage
@_spi(SchemaBasedSerde)
import class Smithy.Schema

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

    public var mediaType: String? { "application/octet-stream" }
}
