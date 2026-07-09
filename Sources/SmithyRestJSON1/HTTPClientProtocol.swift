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
import enum Smithy.ClientError
import class Smithy.Context
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID
@_spi(SchemaBasedSerde)
import class Smithy.StreamingTrait
@_spi(SchemaBasedSerde)
import struct SmithyEventStreams.EventStreamDeserializer
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
public struct HTTPClientProtocol: SmithySerialization.ClientProtocol {

    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    public var id: ShapeID { .init("aws.protocols", "restJson1") }

    public var codec: any SmithySerialization.Codec { Codec() }

    public init() {}

    public func serializeRequest<Input, Output>(
        operation: Operation<Input, Output>,
        input: Input,
        requestBuilder: HTTPRequestBuilder,
        context: Context
    ) throws where Input: SerializableStruct, Output: DeserializableStruct {
        let serializer = try codec.makeSerializer()
        try input.serialize(serializer)
        let data = try serializer.data
        requestBuilder.withBody(.data(data))
    }

    public func deserializeResponse<Input, Output>(
        operation: Operation<Input, Output>,
        context: Context,
        response: HTTPResponse
    ) async throws -> Output where Input: SerializableStruct, Output: DeserializableStruct {
        if (200..<300).contains(response.statusCode.rawValue) {
            if response.isEventStream {
                let eventStreamDeserializer = EventStreamDeserializer(codec: codec, response: response)
                return try Output.deserialize(eventStreamDeserializer)
            } else {
                let data = try await response.body.readData() ?? Data()
                let deserializer = try codec.makeDeserializer(data: data)
                return try Output.deserialize(deserializer)
            }
        } else {
            // Read entire response body into memory
            let responseBodyData = try await response.body.readData() ?? Data()

            // Get the error type registry for this operation
            let errorTypeRegistry = operation.errorTypeRegistry

            // Attempt to parse basic error fields (__type, message) from error response body.
            let typeDeserializer = try codec.makeDeserializer(data: responseBodyData)
//            let baseError = try BaseError.deserialize(typeDeserializer)

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
//            } else if let nonQueryCompatibleErrorCode = strippedCode(baseError: baseError, response: response) {
//                // Resolve the final error code to be used in matching the error to a modeled type
//                registryEntry = errorTypeRegistry.find { entry in
//                     entry.schema.id.name == nonQueryCompatibleErrorCode
//                }
//                code = nonQueryCompatibleErrorCode
            } else {
                registryEntry = nil
                code = nil
            }

            // If a type registry match was found, create that type from the response & throw
            if let registryEntry {

                // Code matched a modeled error.  Deserialize the error to the specific type specified in the code
                let errorDeserializer = try codec.makeDeserializer(data: responseBodyData)
                let error = try registryEntry.swiftType.deserialize(errorDeserializer)

                // Cast the error so that we can fill its fields
                guard var modeledError = error as? ServiceError & HTTPError & Error else {
                    throw ClientError.invalidValue(
                        "Modeled error does not conform to ServiceError & HTTPError & Error.  " +
                        "This should never happen, please file a bug on aws-sdk-swift."
                    )
                }
//                modeledError.message = baseError.message
                modeledError.httpResponse = response

                // Throw the error to the caller
                throw modeledError
            } else {
                // If no type registry match was found, create & throw an UnknownHTTPServiceError
                throw UnknownHTTPServiceError(
                    httpResponse: response,
//                    message: baseError.message,
                    typeName: code
                )
            }
        }
    }

//    private func strippedCode(baseError: BaseError, response: HTTPResponse) -> String? {
//        // Code can come from `__type` or `code` field in body, or from `X-Amzn-Errortype` header
//        guard let code = baseError.__type ?? baseError.code ?? response.headers.value(for: "X-Amzn-Errortype") else {
//            return nil
//        }
//
//        // Strip the namespace & other metadata from code.  See:
//        // https://smithy.io/2.0/aws/protocols/aws-json-1_0-protocol.html#operation-error-serialization
//        return code.substringAfter("#").substringBefore(":").trim()
//    }
}

extension HTTPResponse {

    var isEventStream: Bool {
        headers.value(for: "Content-Type")?.contains("application/vnd.amazon.eventstream") ?? false
    }

    func queryCompatibleErrorCode<Input, Output>(for operation: Operation<Input, Output>) throws -> String? {
        guard operation.serviceSchema.hasTrait(AWSQueryCompatibleTrait.self) else { return nil }
        let headerValue = headers.value(for: "x-amzn-query-error")
        return try AwsQueryCompatibleErrorDetails.parse(headerValue)?.code
    }
}
