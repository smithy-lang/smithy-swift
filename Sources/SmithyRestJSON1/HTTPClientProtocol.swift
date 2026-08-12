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
@_spi(SchemaBasedSerde)
import class Smithy.HTTPTrait
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPRequestBuilder
import class SmithyHTTPAPI.HTTPResponse
@_spi(SchemaBasedSerde)
import class SmithyHTTPAPI.HTTPLabelSerializer
@_spi(SchemaBasedSerde)
import class SmithyHTTPAPI.HTTPQuerySerializer
@_spi(SchemaBasedSerde)
import class SmithyHTTPAPI.HTTPQueryParamsSerializer
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

        // Use the operation's HTTP trait plus the input members' HTTPLabel trait
        // to populate a complete path for the HTTP request.
        if let uri = operation.schema.getTrait(HTTPTrait.self)?.uri {
            let labelSerializer = HTTPLabelSerializer(uri: uri)
            try input.serializeMembers(operation.inputSchema, labelSerializer)
            context.path = labelSerializer.uri
            requestBuilder.withPath(labelSerializer.uri)
        }

        // Serialize any HTTP query-bound members to the HTTP request's query string
        let querySerializer = HTTPQuerySerializer()
        try input.serializeMembers(operation.inputSchema, querySerializer)
        requestBuilder.withQueryItems(querySerializer.queryItems)

        // Serialize any HTTP query-params-bound members to the HTTP request's query string
        // Skip any query with a name that was already added
        let queryParamsSerializer = HTTPQueryParamsSerializer()
        try input.serializeMembers(operation.inputSchema, queryParamsSerializer)
        queryParamsSerializer.queryItems.forEach { queryItem in
            if !requestBuilder.queryItems.contains { $0.name == queryItem.name } {
                requestBuilder.withQueryItem(queryItem)
            }
        }

        // Serialize the input into the request body.
        // HTTP bindings and HTTP payload trait are not yet accounted for.
        let serializer = try self.codec.makeSerializer()
        try input.serialize(serializer)
        requestBuilder.withBody(.data(try serializer.data))
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
