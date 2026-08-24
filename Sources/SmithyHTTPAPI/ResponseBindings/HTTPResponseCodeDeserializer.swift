//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ThrowByDefaultShapeDeserializer

/// A deserializer that deserializes the HTTP status code to an integer.
///
/// Only integer is supported.
@_spi(SchemaBasedSerde)
public class HTTPResponseCodeDeserializer: ThrowByDefaultShapeDeserializer {
    let response: HTTPResponse

    public init(response: HTTPResponse) {
        self.response = response
    }

    public func readInteger(_ schema: Schema) throws -> Int32 {
        Int32(response.statusCode.rawValue)
    }
}
