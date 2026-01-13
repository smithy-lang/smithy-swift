//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct ClientRuntime.CborValidateResponseHeaderMiddleware
import struct ClientRuntime.ContentLengthMiddleware
import struct ClientRuntime.ContentTypeMiddleware
import protocol ClientRuntime.HTTPConfigurating
import struct ClientRuntime.MutateHeadersMiddleware
import class ClientRuntime.OrchestratorBuilder
import struct ClientRuntime.SchemaBodyMiddleware
import struct ClientRuntime.SchemaDeserializeMiddleware
import struct ClientRuntime.URLPathMiddleware
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse
import struct SmithySerialization.Operation

public struct Configurator: HTTPConfigurating {

    public init() {}

    // This will be modified by AWS RPCv2CBOR services to customize ClientProtocol behavior
    public var makeHTTPClientProtocol: @Sendable () -> HTTPClientProtocol = { HTTPClientProtocol() }

    public func configure<InputType, OutputType>(
        _ operation: Operation<InputType, OutputType>,
        _ builder: OrchestratorBuilder<InputType, OutputType, HTTPRequest, HTTPResponse>
    ) {
        // Create a client protocol & use it to serialize / deserialize
        let clientProtocol = makeHTTPClientProtocol()
        builder.serialize(SchemaBodyMiddleware(operation, clientProtocol))
        builder.deserialize(SchemaDeserializeMiddleware(operation, clientProtocol))

        // Add content-type and content-length, and accept headers
        builder.interceptors.add(ContentTypeMiddleware(contentType: "application/cbor"))
        builder.interceptors.add(ContentLengthMiddleware()) // don't add this when event streaming
        builder.interceptors.add(MutateHeadersMiddleware(overrides: ["Accept": "application/cbor"]))

        // Add the smithy-protocol header
        builder.interceptors.add(MutateHeadersMiddleware(overrides: ["smithy-protocol": "rpc-v2-cbor"]))

        // Set the URL path as required by the RPCv2CBOR spec
        builder.interceptors.add(URLPathMiddleware { _ in
            let serviceName = operation.serviceSchema.id.name.urlPercentEncoding()
            let operationName = operation.schema.id.name.urlPercentEncoding()
            return "/service/\(serviceName)/operation/\(operationName)"
        })

        // Set the validate-response header
        builder.interceptors.add(ClientRuntime.CborValidateResponseHeaderMiddleware<InputType, OutputType>())
    }
}
