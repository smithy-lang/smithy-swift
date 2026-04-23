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
import struct Smithy.HttpPayloadTrait
import struct Smithy.Schema
import struct Smithy.ShapeID
import struct Smithy.StreamingTrait
import struct Smithy.TargetsUnitTrait
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPRequestBuilder
import class SmithyHTTPAPI.HTTPResponse
import protocol SmithySerialization.ClientProtocol
import protocol SmithySerialization.Codec
import protocol SmithySerialization.DeserializableStruct
import struct SmithySerialization.Operation
import struct SmithySerialization.TypeRegistry
@_spi(SmithyReadWrite) import struct SmithyXML.NodeInfo
@_spi(SmithyReadWrite) import class SmithyXML.Reader

public struct HTTPClientProtocol: SmithySerialization.ClientProtocol, Sendable {
    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    public let id = ShapeID("aws.protocols", "restXml")
    public let codec: SmithySerialization.Codec = Codec()
    public let noErrorWrapping: Bool

    public init(noErrorWrapping: Bool = false) {
        self.noErrorWrapping = noErrorWrapping
    }

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

        let serializer = Serializer()
        try input.serialize(serializer)
        if let streamingBody = serializer.streamingBody {
            requestBuilder.withBody(streamingBody)
        } else {
            let data = try serializer.data
            requestBuilder.withBody(.data(data))
        }
    }

    public func deserializeResponse<Input, Output: DeserializableStruct>(
        operation: Operation<Input, Output>,
        context: Context,
        response: HTTPResponse
    ) async throws -> Output {
        if (200..<300).contains(response.statusCode.rawValue) {
            // Check if the output has a streaming @httpPayload member (e.g. S3 GetObject body).
            // If so, pass the ByteStream through without consuming it.
            // Check both the member's own traits (which inherit from the target) and the
            // target's traits directly, to be resilient to trait resolution differences.
            let hasStreamingPayload = operation.outputSchema.members.contains { member in
                guard member.hasTrait(HttpPayloadTrait.self) else { return false }
                return member.hasTrait(StreamingTrait.self)
                    || (member.target?.hasTrait(StreamingTrait.self) ?? false)
            }
            if hasStreamingPayload {
                let deserializer = Deserializer(httpResponse: response, bodyStream: response.body)
                return try Output.deserialize(deserializer)
            }
            let bodyData = try await response.body.readData() ?? Data()
            let deserializer = try Deserializer(httpResponse: response, bodyData: bodyData)
            return try Output.deserialize(deserializer)
        } else {
            let bodyData = try await response.body.readData() ?? Data()
            let errorTypeRegistry = operation.errorTypeRegistry

            // Parse error response; RestXML errors may be wrapped in <Error> element
            let errorDeserializer = try Deserializer(data: bodyData)
            let errorReader = errorDeserializer.reader

            let baseErrorDeserializer: Deserializer
            if noErrorWrapping {
                baseErrorDeserializer = errorDeserializer
            } else {
                let errorElement = errorReader.children.first {
                    $0.nodeInfo.name == "Error"
                } ?? errorReader
                baseErrorDeserializer = Deserializer(reader: errorElement)
            }

            let baseError = try BaseError.deserialize(baseErrorDeserializer)
            let code = baseError.code

            let registryEntry: TypeRegistry.Entry?
            if let code {
                registryEntry = errorTypeRegistry.find { entry in
                    entry.schema.id.name == code
                }
            } else {
                registryEntry = nil
            }

            if let registryEntry {
                let specificDeserializer: Deserializer
                if noErrorWrapping {
                    specificDeserializer = errorDeserializer
                } else {
                    let errorElement = errorReader.children.first {
                        $0.nodeInfo.name == "Error"
                    } ?? errorReader
                    specificDeserializer = Deserializer(reader: errorElement, httpResponse: response)
                }
                let error = try registryEntry.swiftType.deserialize(specificDeserializer)

                guard var modeledError = error as? ServiceError & HTTPError & Error else {
                    throw ClientError.invalidValue(
                        "Modeled error does not conform to ServiceError & HTTPError & Error."
                    )
                }
                modeledError.message = baseError.message
                modeledError.httpResponse = response
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
