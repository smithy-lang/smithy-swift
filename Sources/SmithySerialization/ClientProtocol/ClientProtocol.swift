//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import protocol Smithy.RequestMessage
import protocol Smithy.ResponseMessage
import struct Smithy.ShapeID

public protocol ClientProtocol<RequestType, ResponseType>: Sendable {
    associatedtype RequestType: RequestMessage
    associatedtype ResponseType: ResponseMessage

    /// The shape ID of the AWS or Smithy protocol that this type implements.
    ///
    /// Example: `aws.protocols#awsJson1_0`, `smithy.protocols#rpcv2Cbor`
    var id: ShapeID { get }

    /// The codec for this protocol.
    var codec: Codec { get }

    func serializeRequest<Input: SerializableStruct, Output: DeserializableStruct>(
        operation: Operation<Input, Output>,
        input: Input,
        requestBuilder: RequestType.RequestBuilderType,
        context: Context
    ) throws

    func deserializeResponse<Input: SerializableStruct, Output: DeserializableStruct>(
        operation: Operation<Input, Output>,
        context: Context,
        response: ResponseType
    ) async throws -> Output
}
