//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import class Smithy.Context
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPRequestBuilder
import class SmithyHTTPAPI.HTTPResponse
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ClientProtocol
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.DeserializableStruct
@_spi(SchemaBasedSerde)
import struct SmithySerialization.Operation
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.SerializableStruct

@_spi(SchemaBasedSerde)
public struct HTTPClientProtocol: SmithySerialization.ClientProtocol {

    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    public var id = ShapeID("aws.protocols", "restJson1")

    public var codec: any SmithySerialization.Codec { Codec() }

    public init() {}

    public func serializeRequest<Input, Output>(
        operation: Operation<Input, Output>,
        input: Input,
        requestBuilder: HTTPRequestBuilder,
        context: Context
    ) throws where Input: SerializableStruct, Output: DeserializableStruct {
        // This type is incomplete & not yet used in production.
        // This method body remains empty for now.
        // Will provide complete body for this later.
    }

    public func deserializeResponse<Input, Output>(
        operation: Operation<Input, Output>,
        context: Context,
        response: HTTPResponse
    ) async throws -> Output where Input: SerializableStruct, Output: DeserializableStruct {
        // This type is incomplete & not yet used in production.
        // Filled this method in just enough to compile for now.
        // Will provide complete body for this later.
        let data = try await response.body.readData() ?? Data()
        let deserializer = try codec.makeDeserializer(data: data)
        return try Output.deserialize(deserializer)
    }
}
