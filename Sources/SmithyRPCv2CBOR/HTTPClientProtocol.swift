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
import struct Smithy.AWSQueryCompatibleTrait
import struct Smithy.AWSQueryErrorTrait
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
        let data = try serializer.data

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
                registryEntry = try errorTypeRegistry.find { entry in
                    // Try to match x-amzn-query-error on the name in the AWSQueryError trait, else on a shape name.
                    // This matches previous error matching behavior; see ErrorShapeName.kt
                    let queryErrorCode = try entry.schema.getTrait(AWSQueryErrorTrait.self)?.code
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

extension HTTPResponse {

    func queryCompatibleErrorCode<Input, Output>(for operation: Operation<Input, Output>) throws -> String? {
        guard operation.serviceSchema.hasTrait(AWSQueryCompatibleTrait.self) else { return nil }
        let headerValue = headers.value(for: "x-amzn-query-error")
        return try AwsQueryCompatibleErrorDetails.parse(headerValue)?.code
    }
}
