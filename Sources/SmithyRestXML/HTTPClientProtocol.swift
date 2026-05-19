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
import struct Smithy.HttpPayloadTrait
@_spi(SchemaBasedSerde)
import struct Smithy.Schema
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID
@_spi(SchemaBasedSerde)
import struct Smithy.StreamingTrait
@_spi(SchemaBasedSerde)
import struct Smithy.TargetsUnitTrait
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
import struct SmithySerialization.TypeRegistry
@_spi(SmithyReadWrite) import struct SmithyXML.NodeInfo
@_spi(SmithyReadWrite) import class SmithyXML.Reader

@_spi(SchemaBasedSerde)
public struct HTTPClientProtocol: SmithySerialization.ClientProtocol, Sendable {
    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    public let id = ShapeID("aws.protocols", "restXml")
    public let codec: SmithySerialization.Codec = Codec()
    public let noErrorWrapping: Bool
    public let handleEmpty404: Bool

    private let customErrorResolver: (
        @Sendable (HTTPResponse, Data, TypeRegistry, Bool) async throws -> (any Error)?
    )?

    private let errorPostProcessor: (
        @Sendable (inout any (ServiceError & HTTPError & Error), HTTPResponse) -> Void
    )?

    public init(noErrorWrapping: Bool = false, handleEmpty404: Bool = false) {
        self.init(
            noErrorWrapping: noErrorWrapping,
            handleEmpty404: handleEmpty404,
            customErrorResolver: nil,
            errorPostProcessor: nil
        )
    }

    private init(
        noErrorWrapping: Bool,
        handleEmpty404: Bool,
        customErrorResolver: (@Sendable (HTTPResponse, Data, TypeRegistry, Bool) async throws -> (any Error)?)?,
        errorPostProcessor: (@Sendable (inout any (ServiceError & HTTPError & Error), HTTPResponse) -> Void)?
    ) {
        self.noErrorWrapping = noErrorWrapping
        self.handleEmpty404 = handleEmpty404
        self.customErrorResolver = customErrorResolver
        self.errorPostProcessor = errorPostProcessor
    }

    public func withCustomErrorResolver(
        _ resolver: @escaping @Sendable (HTTPResponse, Data, TypeRegistry, Bool) async throws -> (any Error)?
    ) -> HTTPClientProtocol {
        HTTPClientProtocol(
            noErrorWrapping: noErrorWrapping,
            handleEmpty404: handleEmpty404,
            customErrorResolver: resolver,
            errorPostProcessor: errorPostProcessor
        )
    }

    public func withErrorPostProcessor(
        _ postProcessor: @escaping @Sendable (inout any (ServiceError & HTTPError & Error), HTTPResponse) -> Void
    ) -> HTTPClientProtocol {
        HTTPClientProtocol(
            noErrorWrapping: noErrorWrapping,
            handleEmpty404: handleEmpty404,
            customErrorResolver: customErrorResolver,
            errorPostProcessor: postProcessor
        )
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
            let hasEventStreamPayload = operation.outputSchema.members.contains { member in
                guard member.hasTrait(HttpPayloadTrait.self) else { return false }
                guard member.hasTrait(StreamingTrait.self)
                    || (member.target?.hasTrait(StreamingTrait.self) ?? false)
                else { return false }
                return (member.target ?? member).type == .union
            }
            if hasEventStreamPayload {
                let eventStreamDeserializer = EventStreamDeserializer(codec: codec, response: response)
                return try Output.deserialize(eventStreamDeserializer)
            }
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

            if let customErrorResolver,
               let resolvedError = try await customErrorResolver(
                response, bodyData, errorTypeRegistry, noErrorWrapping
               ) {
                throw resolvedError
            }

            // Tolerate non-XML error bodies (HTML 5xx pages, truncated responses)
            // by surfacing UnknownHTTPServiceError instead of leaking a parse error.
            guard let errorDeserializer = try? Deserializer(data: bodyData) else {
                throw UnknownHTTPServiceError(
                    httpResponse: response,
                    message: nil,
                    typeName: nil
                )
            }
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
            } else if handleEmpty404 && bodyData.isEmpty && response.statusCode == .notFound {
                registryEntry = errorTypeRegistry.find { entry in
                    entry.schema.id.name == "NotFound"
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
                        + " This should never happen, please file a bug on aws-sdk-swift."
                    )
                }
                modeledError.message = baseError.message
                modeledError.httpResponse = response
                errorPostProcessor?(&modeledError, response)
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
