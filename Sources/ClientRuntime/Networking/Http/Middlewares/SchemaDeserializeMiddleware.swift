//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import class Foundation.DateFormatter
import struct Foundation.Locale
import struct Foundation.TimeInterval
import struct Foundation.TimeZone
import struct Foundation.UUID
import class Smithy.Context
import protocol Smithy.ResponseMessageDeserializer
import SmithyHTTPAPI
import protocol SmithySerialization.ClientProtocol
import protocol SmithySerialization.DeserializableStruct
import struct SmithySerialization.Operation
import protocol SmithySerialization.SerializableStruct

public struct SchemaDeserializeMiddleware<
    Input: SerializableStruct,
    Output: DeserializableStruct,
    ClientProtocol: SmithySerialization.ClientProtocol
> where ClientProtocol.ResponseType == HTTPResponse {
    public var id: String = "Deserialize"
    let operation: Operation<Input, Output>
    let clientProtocol: ClientProtocol

    public init(_ operation: Operation<Input, Output>, _ clientProtocol: ClientProtocol) {
        self.operation = operation
        self.clientProtocol = clientProtocol
    }
}

extension SchemaDeserializeMiddleware: ResponseMessageDeserializer {

    public func deserialize(response: ClientProtocol.ResponseType, attributes: Context) async throws -> Output {
        if let responseDateString = response.headers.value(for: "Date") {
            let estimatedSkew = getEstimatedSkew(now: Date(), responseDateString: responseDateString)
            attributes.estimatedSkew = estimatedSkew
        }

        // check if the response body was affected by a previous middleware
        if let contextBody = attributes.httpResponse?.body {
            response.body = contextBody
        }

        // if the response is an error and the response body is a stream, we need to cache the stream so
        // that it can be read again.
        //
        // error deserialization reads the stream multiple times to first deserialize the protocol error
        // eg. [RestJSONError](https://github.com/awslabs/aws-sdk-swift/blob/d1d18eefb7457ed27d416b372573a1f815004eb1/Sources/Core/AWSClientRuntime/Protocols/RestJSON/RestJSONError.swift#L38,
        // and then the service error eg. [AccountNotFoundException](https://github.com/awslabs/aws-sdk-swift/blob/d1d18eefb7457ed27d416b372573a1f815004eb1/Sources/Services/AWSCloudTrail/models/Models.swift#L62)
        if response.statusCode.rawValue > 299 {
            let bodyData = try await response.body.readData()
            response.body = .data(bodyData)
        }

        return try await clientProtocol.deserializeResponse(
            operation: operation,
            context: attributes,
            response: response
        )
    }
}
