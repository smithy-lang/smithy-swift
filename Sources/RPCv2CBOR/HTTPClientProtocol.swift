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
import struct Smithy.Schema
import struct Smithy.ShapeID
import struct Smithy.TargetsUnitTrait
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPRequestBuilder
import class SmithyHTTPAPI.HTTPResponse
import protocol SmithySerialization.ClientProtocol
import protocol SmithySerialization.Codec
import protocol SmithySerialization.DeserializableStruct
import struct SmithySerialization.Operation
import struct SmithySerialization.TypeRegistry

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
        let serializer = try codec.makeSerializer()
        try input.serialize(serializer)
        let data = serializer.data

        // Add the data to the request body.
        let body = ByteStream.data(data)
        requestBuilder.withBody(body)
    }

    public func deserializeResponse<Input, Output: DeserializableStruct>(
        operation: Operation<Input, Output>,
        context: Context,
        response: HTTPResponse
    ) async throws -> Output {
        let bodyData = try await response.body.readData() ?? Data()
        if (200..<300).contains(response.statusCode.rawValue) {
            // HTTP code indicates success.  Attempt to parse the output type & return it.
            let deserializer = try codec.makeDeserializer(data: bodyData)
            return try Output.deserialize(deserializer)
        } else {
            // Since HTTP code was not 2xx or 3xx, treat response as an error.

            // Deserialize the rpcv2cbor "base error" to determine the error code.
            let typeDeserializer = try codec.makeDeserializer(data: bodyData)
            let baseError = try BaseError.deserialize(typeDeserializer)

            // Resolve the final error code to be used in matching the error to a modeled type
            let code = (baseError.__type ?? "NoCodeFound").substringAfter("#")

            // Find an entry where the shape name is the same as the code.
            let registryEntry = operation.errorTypeRegistry.codeLookup(code: code) { code, entry in
                code == entry.schema.id.name
            }

            // If a type registry match was found, create that type from the response & throw
            // Else create & throw an UnknownHTTPServiceError
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
                throw UnknownHTTPServiceError(
                    httpResponse: response,
                    message: baseError.message,
                    typeName: code
                )
            }
        }
    }
}
