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
@_spi(SchemaBasedSerde)
import class Smithy.AWSQueryErrorTrait
import enum Smithy.ClientError
import class Smithy.Context
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID
@_spi(SchemaBasedSerde)
import class SmithyFormURL.Serializer
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
import class SmithyXML.Deserializer

/// The client side of the `ec2Query` protocol.
///
/// See https://smithy.io/2.0/aws/protocols/aws-ec2-query-protocol.html
@_spi(SchemaBasedSerde)
public struct HTTPClientProtocol: SmithySerialization.ClientProtocol {

    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    /// The version of the service, which is sent with every request as the `Version` parameter.
    public let version: String

    public var id: ShapeID { .init("aws.protocols", "ec2Query") }

    public var codec: any SmithySerialization.Codec { Codec() }

    /// Creates the ec2Query client protocol for a service.
    /// - Parameter version: The `version` of the service shape, i.e. `2010-05-08`.
    public init(version: String) {
        self.version = version
    }

    public func serializeRequest<Input, Output>(
        operation: Operation<Input, Output>,
        input: Input,
        requestBuilder: HTTPRequestBuilder,
        context: Context
    ) throws where Input: SerializableStruct, Output: DeserializableStruct {
        // The body is the input's members, preceded by the Action & Version parameters.
        let serializer = SmithyFormURL.Serializer(
            variant: .ec2Query,
            action: operation.schema.id.name,
            version: version
        )
        try input.serialize(serializer)
        requestBuilder.withBody(.data(try serializer.data))
    }

    public func deserializeResponse<Input, Output>(
        operation: Operation<Input, Output>,
        context: Context,
        response: HTTPResponse
    ) async throws -> Output where Input: SerializableStruct, Output: DeserializableStruct {
        let data = try await response.body.readData() ?? Data()

        if response.statusCode.isSuccess {
            // The output is the <OperationNameResponse> element, with no other wrapper.
            return try Output.deserialize(SmithyXML.Deserializer(data: data))
        }

        // The error is wrapped in <Response><Errors><Error>.  Read its code & message first.
        // A body that is not valid XML, i.e. one produced by an intermediary, yields no fields
        // instead of an error, so that the HTTP response is still surfaced to the caller.
        let baseError = try? BaseError.deserialize(Self.errorDeserializer(data: data))

        // If the error has no code, it can't be matched to a modeled error.
        guard let code = baseError?.code else {
            throw UnknownHTTPServiceError(httpResponse: response, message: baseError?.message, typeName: nil)
        }

        // Find the modeled error for the code.  The code is the one in the error's awsQueryError trait,
        // else the error's shape name.  ec2Query services rarely use awsQueryError, but it is honored
        // the same as in awsQuery.
        let registryEntry = operation.errorTypeRegistry.find { entry in
            (entry.schema.getTrait(AWSQueryErrorTrait.self)?.code ?? entry.schema.id.name) == code
        }
        guard let registryEntry else {
            throw UnknownHTTPServiceError(httpResponse: response, message: baseError?.message, typeName: code)
        }

        // Deserialize the modeled error from the Errors/Error element.  The XML is read again, since the
        // deserializer reads the XML as it is parsed, and the base error fields above were read already.
        let error = try registryEntry.swiftType.deserialize(Self.errorDeserializer(data: data))

        // Cast the error so that we can fill its fields
        guard var modeledError = error as? ServiceError & HTTPError & Error else {
            throw ClientError.invalidValue(
                "Modeled error does not conform to ServiceError & HTTPError & Error.  " +
                "This should never happen, please file a bug on aws-sdk-swift."
            )
        }

        // Fill in the message, if there was one.  A modeled `message` member is
        // deserialized into the error's `properties` and is left untouched here.
        if let message = baseError?.message {
            modeledError.message = message
        }
        modeledError.httpResponse = response

        // Throw the error to the caller
        throw modeledError
    }

    /// Returns a deserializer for the `Errors/Error` element of an ec2Query error response.
    private static func errorDeserializer(data: Data) throws -> SmithyXML.Deserializer {
        try SmithyXML.Deserializer(data: data).child(named: "Errors").child(named: "Error")
    }
}
