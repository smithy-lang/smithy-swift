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
import struct Smithy.ShapeID
import struct Smithy.TargetsUnitTrait
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPRequestBuilder
import class SmithyHTTPAPI.HTTPResponse
import protocol SmithySerialization.ClientProtocol
import protocol SmithySerialization.Codec
import protocol SmithySerialization.DeserializableStruct
import struct SmithySerialization.Operation

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
        guard !operation.inputSchema.hasTrait(TargetsUnitTrait.self) else {
            requestBuilder.withBody(.data(nil))
            return
        }
        let serializer = try codec.makeSerializer()
        try input.serialize(serializer)
        let data = serializer.data
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
            let deserializer = try codec.makeDeserializer(data: bodyData)
            return try Output.deserialize(deserializer)
        } else {
            let typeDeserializer = try codec.makeDeserializer(data: bodyData)
            let baseError = try BaseError.deserialize(typeDeserializer)
            let specialErrorCode = try errorCodeBlock(response)
            let resolvedErrorCode = (specialErrorCode ?? baseError.__type ?? "NoCodeFound").substringAfter("#")
            if let entry = try operation.errorTypeRegistry.codeLookup(
                serviceSchema: operation.serviceSchema,
                code: resolvedErrorCode
            ) {
                let errorDeserializer = try codec.makeDeserializer(data: bodyData)
                let error = try entry.swiftType.deserialize(errorDeserializer)
                guard var modeledError = error as? ServiceError & HTTPError & Error else {
                    throw ClientError.invalidValue(
                        "Modeled error does not conform to ServiceError & HTTPError & Error.  " +
                        "This should never happen, please file a bug on aws-sdk-swift."
                    )
                }
                modeledError.message = baseError.message
                modeledError.httpResponse = response
                throw modeledError
            } else {
                throw unknownErrorBlock(resolvedErrorCode, baseError.message, response)
            }
        }
    }
}
