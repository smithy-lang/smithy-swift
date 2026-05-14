//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import Smithy
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
public struct SchemaBodyMiddleware<Input: SerializableStruct, Output: DeserializableStruct, CP: ClientProtocol> {
    public let id: Swift.String = "BodyMiddleware"
    let operation: Operation<Input, Output>
    let clientProtocol: CP

    public init(_ operation: Operation<Input, Output>, _ clientProtocol: CP) {
        self.operation = operation
        self.clientProtocol = clientProtocol
    }
}

extension SchemaBodyMiddleware: RequestMessageSerializer {
    public typealias InputType = Input
    public typealias RequestType = CP.RequestType

    public func apply(input: Input, builder: RequestType.RequestBuilderType, attributes: Context) throws {
        do {
            return try clientProtocol.serializeRequest(
                operation: operation,
                input: input,
                requestBuilder: builder,
                context: attributes
            )
        } catch {
            throw ClientError.serializationFailed(error.localizedDescription)
        }
    }
}
