//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import enum Smithy.ByteStream
import class Smithy.Context
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID
@_spi(SchemaBasedSerde)
import class SmithyHTTPAPI.HTTPBindingsSerializer
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
public struct HTTPClientProtocol: ClientProtocol {

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
        // This method is incomplete.  Missing:
        // - Request event streams
        // - Several HTTP bindings
        // Will be filled in as these other items are completed.

        // Create a HTTP binding serializer & serialize the input to it
        let serializer = try HTTPBindingsSerializer(codec: self.codec, operation: operation)
        try input.serialize(serializer)

        // Populate the request with fields from the binding serializer
        requestBuilder.withMethod(serializer.method)
        requestBuilder.withPath(serializer.uri)
        requestBuilder.withQueryItems(serializer.queryItems)
        requestBuilder.withHeaders(serializer.headers)
        requestBuilder.withBody(ByteStream.data(try serializer.data))
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
