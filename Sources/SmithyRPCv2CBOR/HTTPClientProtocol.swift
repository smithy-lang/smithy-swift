//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class ClientRuntime.AwsQueryCompatibleErrorDetails
import protocol ClientRuntime.HTTPError
import protocol ClientRuntime.ServiceError
import struct ClientRuntime.UnknownHTTPServiceError
import struct Foundation.Data
@_spi(SchemaBasedSerde)
import class Smithy.AWSQueryCompatibleTrait
@_spi(SchemaBasedSerde)
import class Smithy.AWSQueryErrorTrait
import enum Smithy.ByteStream
import enum Smithy.ClientError
import class Smithy.Context
import class Smithy.Schema
import struct Smithy.ShapeID
@_spi(SchemaBasedSerde)
import class Smithy.StreamingTrait
import class Smithy.TargetsUnitTrait
@_spi(SmithyEventStreams)
import class SmithyEventStreams.DefaultMessageDecoder
@_spi(SchemaBasedSerde)
import struct SmithyEventStreams.EventStreamDeserializer
@_spi(SchemaBasedSerde)
import class SmithyEventStreams.EventStreamSerializer
import struct SmithyEventStreamsAPI.Header
import struct SmithyEventStreamsAPI.Message
import SmithyEventStreamsAuthAPI
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
import struct SmithySerialization.SerializerError
@_spi(SchemaBasedSerde)
import struct SmithySerialization.TypeRegistry

@_spi(SchemaBasedSerde)
public struct HTTPClientProtocol: SmithySerialization.ClientProtocol, Sendable {
    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    public let requestType = SmithyHTTPAPI.HTTPRequest.self
    public let responseType = SmithyHTTPAPI.HTTPResponse.self

    public let id = ShapeID("smithy.protocols", "rpcv2Cbor")

    public let codec: SmithySerialization.Codec = Codec()

    public init() {}

    public func serializeRequest<Input, Output>(
        operation: Operation<Input, Output>,
        input: Input,
        requestBuilder: HTTPRequestBuilder,
        context: Context
    ) throws {

        // If the operation input targets smithy.api#Unit, don't serialize a body.
        guard !operation.inputSchema.hasTrait(TargetsUnitTrait.self) else {
            requestBuilder.withBody(.data(nil))
            return
        }

        // Serialize the input to data.
        // The CBOR serializer skips an event stream member, so for an event streaming input this
        // serializes only the non-stream members.
        let serializer = try codec.makeSerializer()
        try input.serialize(serializer)
        let data = try serializer.data

        if operation.inputSchema.hasEventStreamMember {
            // The non-stream members are sent in an initial-request event, followed by the events on the stream.
            guard let messageEncoder = context.messageEncoder else {
                throw SerializerError("Message encoder was not configured")
            }
            guard let messageSigner = context.messageSigner else {
                throw SerializerError("Message signer was not configured")
            }
            let initialRequestMessage = Message(
                headers: [
                    Header(name: ":message-type", value: .string("event")),
                    Header(name: ":event-type", value: .string("initial-request")),
                    Header(name: ":content-type", value: .string("application/cbor")),
                ],
                payload: data ?? Data()
            )
            let eventStreamSerializer = EventStreamSerializer(
                codec: codec,
                contentType: "application/cbor",
                messageEncoder: messageEncoder,
                messageSigner: messageSigner,
                initialRequestMessage: initialRequestMessage
            )
            try input.serialize(eventStreamSerializer)
            requestBuilder.withBody(eventStreamSerializer.body)
            if let mediaType = eventStreamSerializer.mediaType {
                requestBuilder.updateHeader(name: "Content-Type", value: mediaType)
            }
        } else {
            // Add the data to the request body.
            let body = ByteStream.data(data)
            requestBuilder.withBody(body)
        }
    }

    public func deserializeResponse<Input, Output: DeserializableStruct>(
        operation: Operation<Input, Output>,
        context: Context,
        response: HTTPResponse
    ) async throws -> Output {
        if (200..<300).contains(response.statusCode.rawValue),
           let streamingMember = operation.outputSchema.eventStreamMember {
            return try await deserializeEventStreamResponse(
                outputSchema: operation.outputSchema,
                streamingMember: streamingMember,
                response: response
            )
        }
        let bodyData = try await response.body.readData() ?? Data()
        if (200..<300).contains(response.statusCode.rawValue) {
            // HTTP code indicates success.  Attempt to parse the output type & return it.
            let deserializer = try codec.makeDeserializer(data: bodyData)
            return try Output.deserialize(deserializer)
        } else {
            // Since HTTP code was not 2xx or 3xx, treat response as an error.

            // Get the error type registry for this operation
            let errorTypeRegistry = operation.errorTypeRegistry

            // Attempt to parse basic error fields (__type, message) from error response body.
            let typeDeserializer = try codec.makeDeserializer(data: bodyData)
            let baseError = try BaseError.deserialize(typeDeserializer)

            // Try to find an error code, and a matching registry entry for the code.
            let registryEntry: TypeRegistry.Entry?
            let code: String?

            if let queryCompatibleErrorCode = try response.queryCompatibleErrorCode(for: operation) {
                // This is a query-compatible service providing a query-compatible error code.
                registryEntry = errorTypeRegistry.find { entry in
                    // Try to match x-amzn-query-error on the name in the AWSQueryError trait, else on a shape name.
                    // This matches previous error matching behavior; see ErrorShapeName.kt
                    let queryErrorCode = entry.schema.getTrait(AWSQueryErrorTrait.self)?.code
                    let shapeName = entry.schema.id.name
                    return queryCompatibleErrorCode == queryErrorCode ?? shapeName
                }
                code = queryCompatibleErrorCode
            } else if let codeFromType = baseError.__type?.substringAfter("#") {
                // Resolve the final error code to be used in matching the error to a modeled type
                registryEntry = errorTypeRegistry.find { entry in
                     entry.schema.id.name == codeFromType
                }
                code = codeFromType
            } else {
                registryEntry = nil
                code = nil
            }

            // If a type registry match was found, create that type from the response & throw
            if let registryEntry {

                // Code matched a modeled error.  Deserialize the error to the specific type specified in the code
                let errorDeserializer = try codec.makeDeserializer(data: bodyData)
                let error = try registryEntry.swiftType.deserialize(errorDeserializer)

                // Cast the error so that we can fill its fields
                guard var modeledError = error as? ServiceError & HTTPError & Error else {
                    throw ClientError.invalidValue(
                        "Modeled error does not conform to ServiceError & HTTPError & Error.  " +
                        "This should never happen, please file a bug on aws-sdk-swift."
                    )
                }
                modeledError.message = baseError.message
                modeledError.httpResponse = response

                // Throw the error to the caller
                throw modeledError
            } else {
                // If no type registry match was found, create & throw an UnknownHTTPServiceError
                throw UnknownHTTPServiceError(
                    httpResponse: response,
                    message: baseError.message,
                    typeName: code
                )
            }
        }
    }
}

extension HTTPClientProtocol {

    /// Deserializes a successful response whose output has an event stream member.
    ///
    /// The non-stream output members are read from the payload of the `initial-response` event, if the stream
    /// begins with one.  The rest of the stream is delivered as the output's event stream member.
    ///
    /// When the output has members besides the event stream, this waits for the first message on the stream
    /// before returning, because those members must be filled from the `initial-response`.  A server sending
    /// such an output must send the `initial-response` first.  When the event stream is the only member,
    /// the output is returned without waiting, so that a bidirectional stream whose server waits for request
    /// events before responding cannot deadlock; an `initial-response`, if sent, is dropped by the decoder.
    private func deserializeEventStreamResponse<Output: DeserializableStruct>(
        outputSchema: Schema,
        streamingMember: Schema,
        response: HTTPResponse
    ) async throws -> Output {
        guard case .stream(let stream) = response.body else {
            throw SerializerError("Event stream response did not have a streaming body")
        }

        // If there are non-stream members, read from the stream until the initial-response is received,
        // or the first other message shows that there will be none.  Any messages read past it stay
        // buffered in the decoder.
        let messageDecoder = DefaultMessageDecoder()
        let hasInitialResponseMembers = outputSchema.members.contains { $0.memberName != streamingMember.memberName }
        while hasInitialResponseMembers,
              !messageDecoder.hasResolvedInitialResponse,
              let data = try await stream.readAsync(upToCount: Int.max) {
            try messageDecoder.feed(data: data)
        }

        // Deserialize the non-stream members from the initial-response.  If there is no initial-response,
        // or it has an empty payload, deserialize from an empty CBOR map so the output is still created.
        let emptyCBORMap = Data([0xa0])
        let initialData = messageDecoder.initialResponsePayload.flatMap { $0.isEmpty ? nil : $0 } ?? emptyCBORMap
        var output = try Output.deserialize(codec.makeDeserializer(data: initialData))

        // Deserialize the event stream using the same message decoder, so buffered messages are delivered.
        let eventStreamDeserializer = EventStreamDeserializer(
            codec: codec,
            response: response,
            messageDecoder: messageDecoder
        )
        try output.deserializeMember(streamingMember, eventStreamDeserializer)
        return output
    }
}

private extension Schema {

    /// The member of this structure that targets an event stream union, if any.
    var eventStreamMember: Schema? {
        members.first { $0.type == .union && $0.hasTrait(StreamingTrait.self) }
    }

    var hasEventStreamMember: Bool { eventStreamMember != nil }
}

extension HTTPResponse {

    func queryCompatibleErrorCode<Input, Output>(for operation: Operation<Input, Output>) throws -> String? {
        guard operation.serviceSchema.hasTrait(AWSQueryCompatibleTrait.self) else { return nil }
        let headerValue = headers.value(for: "x-amzn-query-error")
        return try AwsQueryCompatibleErrorDetails.parse(headerValue)?.code
    }
}
