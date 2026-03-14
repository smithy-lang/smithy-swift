//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol ClientRuntime.Interceptor
import protocol ClientRuntime.MutableInput
import enum Smithy.ClientError
import class Smithy.Context
import protocol Smithy.RequestMessage
import protocol Smithy.ResponseMessage
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse
import protocol SmithySerialization.DeserializableStruct
import protocol SmithySerialization.OperationProperties
import protocol SmithySerialization.SerializableStruct

public struct URLPathMiddleware<InputType, OutputType, RequestType: RequestMessage, ResponseType: ResponseMessage> {
    public let id = "RPCv2CBOR.URLPathMiddleware"

    public init() {}
}

extension URLPathMiddleware: Interceptor {

    public func modifyBeforeSerialization(context: some MutableInput<InputType>) async throws {
        let attributes = context.getAttributes()
        guard let operation: any OperationProperties = attributes.getOperationProperties() else {
            throw ClientError.dataNotFound("Operation not set on Context")
        }
        let serviceName = operation.serviceSchema.id.name.urlPercentEncoding()
        let operationName = operation.schema.id.name.urlPercentEncoding()
        attributes.path = "/service/\(serviceName)/operation/\(operationName)"
    }
}
