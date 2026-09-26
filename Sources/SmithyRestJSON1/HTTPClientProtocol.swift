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
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID
@_spi(SchemaBasedSerde)
import struct SmithyEventStreams.EventStreamDeserializer
@_spi(SchemaBasedSerde)
import class SmithyEventStreams.EventStreamSerializer
import SmithyEventStreamsAuthAPI
@_spi(SchemaBasedSerde)
import class SmithyHTTPAPI.HTTPBindingsDeserializer
@_spi(SchemaBasedSerde)
import class SmithyHTTPAPI.HTTPBindingsSerializer
@_spi(SchemaBasedSerde)
import class SmithyHTTPAPI.HTTPOperationExtension
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPRequestBuilder
import class SmithyHTTPAPI.HTTPResponse
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ClientProtocol
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.Codec
@_spi(SchemaBasedSerde)
import struct SmithySerialization.DataStreamDeserializer
@_spi(SchemaBasedSerde)
import class SmithySerialization.DataStreamSerializer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.DeserializableStruct
@_spi(SchemaBasedSerde)
import struct SmithySerialization.Operation
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.SerializableStruct
import struct SmithySerialization.SerializerError

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

        // Create a HTTP binding serializer & serialize the input to it
        let serializer = try HTTPBindingsSerializer(
            codec: self.codec,
            operation: operation
        )
        try input.serialize(serializer)

        // Populate the request with fields from the binding serializer
        requestBuilder.withMethod(serializer.method)
        requestBuilder.withPath(serializer.uri)
        requestBuilder.withQueryItems(serializer.queryItems)
        requestBuilder.withHeaders(serializer.headers)

        switch serializer.operationExtension.requestStreamingType {
        case .event:
            guard let messageEncoder = context.messageEncoder else {
                throw SerializerError("Message encoder was not configured")
            }
            guard let messageSigner = context.messageSigner else {
                throw SerializerError("Message signer was not configured")
            }
            let eventStreamSerializer = EventStreamSerializer(
                codec: codec,
                contentType: "application/json",
                messageEncoder: messageEncoder,
                messageSigner: messageSigner
            )
            try input.serializeMembers(operation.inputSchema, eventStreamSerializer)
            requestBuilder.withBody(eventStreamSerializer.body)
            if let mediaType = eventStreamSerializer.mediaType {
                requestBuilder.updateHeader(name: "Content-Type", value: mediaType)
            }
        case .data:
            let dataStreamSerializer = DataStreamSerializer()
            try input.serializeMembers(operation.inputSchema, dataStreamSerializer)
            requestBuilder.withBody(dataStreamSerializer.body)
            if let mediaType = dataStreamSerializer.mediaType {
                requestBuilder.updateHeader(name: "Content-Type", value: mediaType)
            }
        case .none:
            requestBuilder.withBody(try serializer.body)
        }

        // Set the path in the context
        context.path = requestBuilder.path
    }

    public func deserializeResponse<Input, Output>(
        operation: Operation<Input, Output>,
        context: Context,
        response: HTTPResponse
    ) async throws -> Output where Input: SerializableStruct, Output: DeserializableStruct {
        if response.statusCode.isSuccess {
            let operationExtension = try operation.schema.getOrCreateExtension(HTTPOperationExtension.self)
            if let streamingMember = operationExtension.responseStreamingMember {
                // Fill all output members other than the streaming members.
                let deserializer = HTTPBindingsDeserializer(codec: codec, response: response, data: nil)
                var output = try Output.deserialize(deserializer)

                switch streamingMember.type {
                case .union:
                    let eventStreamDeserializer = EventStreamDeserializer(codec: codec, response: response)
                    try output.deserializeMember(streamingMember, eventStreamDeserializer)
                case .blob:
                    let dataStreamDeserializer = DataStreamDeserializer(response: response)
                    try output.deserializeMember(streamingMember, dataStreamDeserializer)
                default:
                    break // streaming trait may only ever be applied to unions & blobs
                }
                return output
            } else {
                // If not a streaming response, read all the data into memory then deserialize
                let data = try await response.body.readData()
                let deserializer = HTTPBindingsDeserializer(codec: codec, response: response, data: data)
                return try Output.deserialize(deserializer)
            }
        } else {
            // Result of HTTP call was error

            // Read the body into memory
            let responseBodyData = try await response.body.readData() ?? Data()

            // Attempt to parse the basic error fields (`__type`, `code`, and the message) from the body.
            // A body that is not valid JSON, i.e. one produced by an intermediary, yields no fields
            // instead of an error, so that the HTTP response is still surfaced to the caller.
            let baseError = try? BaseError.deserialize(codec.makeDeserializer(data: responseBodyData))

            // The message may be in a header, i.e. when the response has no body, else it is in the body.
            let message = response.errorMessageHeader ?? baseError?.resolvedMessage

            // Get the error type, trying the `X-Amzn-Errortype` header first, then the body fields if no header
            let unsanitizedErrorType = response.headers.value(for: "X-Amzn-Errortype")
                ?? baseError?.__type
                ?? baseError?.code

            // If the error type could not be resolved, throw an unknown error
            guard let unsanitizedErrorType else {
                throw UnknownHTTPServiceError(httpResponse: response, message: message, typeName: nil)
            }

            // Strip the namespace & other metadata from the error type.  See:
            // https://smithy.io/2.0/aws/protocols/aws-restjson1-protocol.html#operation-error-serialization
            let errorType = unsanitizedErrorType.substringAfter("#").substringBefore(":").trim()

            // Find the modeled error matching the error type, if there is one
            guard let registryEntry = operation.errorTypeRegistry.find(matcher: { $0.schema.id.name == errorType })
            else {
                // Error type did not resolve to a modeled error, throw an unknown error instead
                throw UnknownHTTPServiceError(httpResponse: response, message: message, typeName: errorType)
            }

            // Error type was resolved.  Deserialize the modeled error from the response body
            let errorDeserializer = HTTPBindingsDeserializer(codec: codec, response: response, data: responseBodyData)
            let error = try registryEntry.swiftType.deserialize(errorDeserializer)

            // Cast the error so that we can fill its fields
            guard var modeledError = error as? ServiceError & HTTPError & Error else {
                throw ClientError.invalidValue(
                    "Modeled error does not conform to ServiceError & HTTPError & Error.  " +
                    "This should never happen, please file a bug on aws-sdk-swift."
                )
            }

            // Fill in the message resolved above, if there was one.  A modeled `message` member is
            // deserialized into the error's `properties` and is left untouched here.
            if let message {
                modeledError.message = message
            }
            modeledError.httpResponse = response

            // Throw the error to the caller
            throw modeledError
        }
    }
}

extension HTTPResponse {

    /// The error message carried in the response headers, if any.
    ///
    /// Three different headers are checked, in this order:
    /// - `x-amzn-error-message`, returned by RESTful services that send no payload, i.e. for a `HEAD` request.
    /// - `:error-message`, returned with event stream errors.
    /// - `x-amzn-ErrorMessage`, returned by some services, i.e. Cognito.  Note that this is a distinct
    ///   header from the first one above, and not merely a difference in case.
    var errorMessageHeader: String? {
        self.headers.value(for: "x-amzn-error-message")
            ?? self.headers.value(for: ":error-message")
            ?? self.headers.value(for: "x-amzn-ErrorMessage")
    }
}
