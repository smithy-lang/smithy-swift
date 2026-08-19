//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol ClientRuntime.HTTPError
import protocol ClientRuntime.ServiceError
import struct ClientRuntime.UnknownHTTPServiceError
import struct Foundation.Data
import enum Smithy.ByteStream
import enum Smithy.ClientError
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
import struct SmithySerialization.TypeRegistry

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

        // Set the path in the context
        context.path = requestBuilder.path
    }

    public func deserializeResponse<Input, Output>(
        operation: Operation<Input, Output>,
        context: Context,
        response: HTTPResponse
    ) async throws -> Output where Input: SerializableStruct, Output: DeserializableStruct {
        let httpStatus = response.statusCode.rawValue
        if httpStatus >= 200 && httpStatus < 400 {
            // Result of HTTP call was success
            return try await deserialize(type: Output.self, httpResponse: response) as! Output
        } else {
            // Result of HTTP call was error

            // Read the data into memory immediately
            let errorResponseData = try await response.body.readData() ?? Data()

            // Get the error code, trying the `X-Amzn-Errortype` header first, then the
            // body fields if no header
            var unsanitizedErrorType: String?
            if let errorCodeHeader = response.headers.value(for: "X-Amzn-Errortype") {
                // Getting error code from header is preferred.
                unsanitizedErrorType = errorCodeHeader
            } else {
                // As a backup to header, check the `__type` and `code` fields in the JSON body.
                let baseErrorDeserializer = try codec.makeDeserializer(data: errorResponseData)
                let baseError = try BaseError.deserialize(baseErrorDeserializer)
                unsanitizedErrorType = baseError.__type ?? baseError.code
            }

            // If the error type could not be resolved, throw an unknown error
            guard let unsanitizedErrorType else {
                throw UnknownHTTPServiceError(
                    httpResponse: response,
                    message: "A code could not be resolved for this error",
                    typeName: nil
                )
            }
            let errorType = unsanitizedErrorType.substringAfter("#").substringBefore(":").trim()
            let registryEntry = operation.errorTypeRegistry.find(matcher: { $0.schema.id.name == errorType })
            if let registryEntry {
                // Error code was resolved.  Create and throw the modeled error
                let deserializer = try codec.makeDeserializer(data: errorResponseData)
                let errorSwiftType = registryEntry.swiftType as! DeserializableStruct.Type
                let error = try await deserialize(type: errorSwiftType, httpResponse: response)
                guard var modeledError = error as? ServiceError & HTTPError & Error else {
                    throw ClientError.invalidValue(
                        "Modeled error does not conform to ServiceError & HTTPError & Error.  " +
                        "This should never happen, please file a bug on aws-sdk-swift."
                    )
                }
                modeledError.httpResponse = response
                throw modeledError
            } else {
                // Error code did not resolve to a modeled error, throw an unknown error instead
                throw UnknownHTTPServiceError(
                    httpResponse: response,
                    message: "A modeled type could not be resolved for this error",
                    typeName: errorType
                )
            }
        }
    }

    private func deserialize(
        type: DeserializableStruct.Type,
        httpResponse: HTTPResponse
    ) async throws -> any DeserializableStruct {
        // This method is incomplete & does not resolve HTTP bindings.
        // Filled this method in just enough to handle non-payload responses for now.
        let data = try await httpResponse.body.readData() ?? Data()
        let deserializer = try codec.makeDeserializer(data: data)
        return try type.deserialize(deserializer)
    }
}
