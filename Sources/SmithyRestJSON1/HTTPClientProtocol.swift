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
        // This method is incomplete.  Missing:
        // - Response event streams
        // - HTTP bindings, including payloads
        // Will be filled in as these other items are completed.

        // Read the body into memory immediately.  The body may be a non-seekable stream, so it can
        // only be read once & the data must be reused for both output & error deserialization.
        let responseBodyData = try await response.body.readData() ?? Data()

        if (200..<300).contains(response.statusCode.rawValue) {
            // Result of HTTP call was success
            let deserializer = try codec.makeDeserializer(data: responseBodyData)
            return try Output.deserialize(deserializer)
        } else {
            // Result of HTTP call was error

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
            let errorDeserializer = try codec.makeDeserializer(data: responseBodyData)
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
