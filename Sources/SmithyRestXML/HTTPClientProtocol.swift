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
import class Smithy.XMLNamespaceTrait
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

/// The client side of the `restXml` protocol.
///
/// Members bound to HTTP headers, query, labels & payloads are handled by the HTTP binding serializers &
/// deserializers, the same as for `restJson1`; members bound to the body are written & read as XML.
///
/// See https://smithy.io/2.0/aws/protocols/aws-restxml-protocol.html
@_spi(SchemaBasedSerde)
public struct HTTPClientProtocol: ClientProtocol {

    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    public var id = ShapeID("aws.protocols", "restXml")

    public var codec: any SmithySerialization.Codec { Codec(defaultNamespace: nil) }

    /// `true` if error responses have the `Error` element at the root, rather than wrapped in `ErrorResponse`.
    ///
    /// This is the `noErrorWrapping` property of the service's `restXml` trait.
    public let noErrorWrapping: Bool

    /// Creates the restXml client protocol for a service.
    /// - Parameter noErrorWrapping: The `noErrorWrapping` property of the service's `restXml` trait.
    public init(noErrorWrapping: Bool = false) {
        self.noErrorWrapping = noErrorWrapping
    }

    /// The codec for an operation's requests & responses.  The root element of a request body is in the
    /// service's `xmlNamespace`, if it has one and the root element has no `xmlNamespace` of its own.
    private func codec<Input, Output>(for operation: Operation<Input, Output>) -> Codec {
        Codec(defaultNamespace: operation.serviceSchema.getTrait(XMLNamespaceTrait.self))
    }

    public func serializeRequest<Input, Output>(
        operation: Operation<Input, Output>,
        input: Input,
        requestBuilder: HTTPRequestBuilder,
        context: Context
    ) throws where Input: SerializableStruct, Output: DeserializableStruct {

        // Create a HTTP binding serializer & serialize the input to it
        let codec = codec(for: operation)
        let serializer = try HTTPBindingsSerializer(
            codec: codec,
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
                contentType: "application/xml",
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

            // Errors are read from the <Error> element, which is wrapped in <ErrorResponse> unless the service
            // uses noErrorWrapping.  Header-bound members of a modeled error are read as for any response.
            let errorCodec = ErrorCodec(noErrorWrapping: noErrorWrapping)

            // Attempt to parse the basic error fields (`Code` and `Message`) from the body.
            // A body that is not valid XML, i.e. one produced by an intermediary, yields no fields
            // instead of an error, so that the HTTP response is still surfaced to the caller.
            let baseError = try? BaseError.deserialize(errorCodec.makeDeserializer(data: responseBodyData))
            let message = baseError?.message

            // A response without an error code, i.e. to a HEAD request, which has no body, is a NotFound
            // error if its status is 404, else it is an unknown error.
            guard let code = baseError?.code ?? (response.statusCode == .notFound ? "NotFound" : nil) else {
                throw UnknownHTTPServiceError(httpResponse: response, message: message, typeName: nil)
            }

            // Find the modeled error matching the error code, if there is one
            guard let registryEntry = operation.errorTypeRegistry.find(matcher: { $0.schema.id.name == code }) else {
                // Error code did not resolve to a modeled error, throw an unknown error instead
                throw UnknownHTTPServiceError(httpResponse: response, message: message, typeName: code)
            }

            // Error code was resolved.  Deserialize the modeled error from the response
            let errorDeserializer = HTTPBindingsDeserializer(
                codec: errorCodec,
                response: response,
                data: responseBodyData
            )
            let error = try registryEntry.swiftType.deserialize(errorDeserializer)

            // Cast the error so that we can fill its fields
            guard var modeledError = error as? ServiceError & HTTPError & Error else {
                throw ClientError.invalidValue(
                    "Modeled error does not conform to ServiceError & HTTPError & Error.  " +
                    "This should never happen, please file a bug on aws-sdk-swift."
                )
            }

            // Fill in the message, if there was one.  A modeled `message` member is
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
