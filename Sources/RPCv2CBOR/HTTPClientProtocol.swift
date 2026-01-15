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
import struct Smithy.AWSQueryCompatibleTrait
import struct Smithy.AWSQueryErrorTrait
import enum Smithy.ByteStream
import enum Smithy.ClientError
import class Smithy.Context
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

    public var errorCodeBlock: @Sendable (HTTPResponse) throws -> String? = { _ in nil }

    public var unknownErrorBlock: @Sendable (String?, String?, HTTPResponse) -> ServiceError & Error =
        { code, message, response in
            UnknownHTTPServiceError(
                httpResponse: response,
                message: message,
                typeName: code
            )
        }

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

            // Use the base error to get the error code in the error response
            let specialErrorCode = try errorCodeBlock(response)
            let resolvedErrorCode = (specialErrorCode ?? baseError.__type ?? "NoCodeFound").substringAfter("#")

            // Determine if this is a query-compatible service and pick the right type registry matcher
            let isQueryCompatible = operation.serviceSchema.hasTrait(AWSQueryCompatibleTrait.self)
            let matcher = isQueryCompatible ? queryMatcher(code:entry:) : nonQueryMatcher(code:entry:)

            // Attempt to locate the matching type in the registry, using the appropriate matcher
            if let entry = try operation.errorTypeRegistry.codeLookup(code: resolvedErrorCode, matcher: matcher) {

                // Code matched a modeled error.  Deserialize the error to the specific type specified in the code
                let errorDeserializer = try codec.makeDeserializer(data: bodyData)
                let error = try entry.swiftType.deserialize(errorDeserializer)

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
                throw unknownErrorBlock(resolvedErrorCode, baseError.message, response)
            }
        }
    }

    private func nonQueryMatcher(code: String, entry: TypeRegistry.Entry) throws -> Bool {
        code == entry.schema.id.name
    }

    private func queryMatcher(code: String, entry: TypeRegistry.Entry) throws -> Bool {
        let queryErrorCode = try entry.schema.getTrait(AWSQueryErrorTrait.self)?.code ?? entry.schema.id.name
        return code == queryErrorCode
    }
}
