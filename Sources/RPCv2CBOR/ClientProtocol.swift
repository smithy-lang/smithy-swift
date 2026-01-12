//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol ClientRuntime.ServiceError
import struct ClientRuntime.UnknownHTTPServiceError
import struct Foundation.Data
import class Smithy.Context
import class Smithy.Schema
import struct Smithy.ShapeID
import struct Smithy.URI
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPRequestBuilder
import class SmithyHTTPAPI.HTTPResponse
import protocol SmithySerialization.ClientProtocol
import protocol SmithySerialization.Codec
import protocol SmithySerialization.DeserializableStruct
import typealias SmithySerialization.ReadStructConsumer
import protocol SmithySerialization.ShapeDeserializer
import struct SmithySerialization.Operation
import enum Smithy.ByteStream

public struct ClientProtocol: SmithySerialization.ClientProtocol {
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
            let baseError = try RPCv2CBORBaseError.deserialize(typeDeserializer)
            let errorTypeID = try ShapeID(baseError.__type ?? "")
            if let ErrorType = operation.errorTypeRegistry[errorTypeID] {
                let errorDeserializer = try codec.makeDeserializer(data: bodyData)
                let error = try ErrorType.deserialize(errorDeserializer)
                if var httpError = error as? ServiceError {
                    httpError.message = baseError.message
                    throw httpError as! Error
                } else {
                    throw error as! Error
                }
            } else {
                let error = UnknownHTTPServiceError(
                    httpResponse: response,
                    message: baseError.message,
                    typeName: baseError.__type
                )
                throw error
            }
        }
    }
}
