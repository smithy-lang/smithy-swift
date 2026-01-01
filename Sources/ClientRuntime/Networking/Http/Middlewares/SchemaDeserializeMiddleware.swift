//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Date
import class Foundation.DateFormatter
import struct Foundation.Locale
import struct Foundation.TimeInterval
import struct Foundation.TimeZone
import struct Foundation.UUID
import class Smithy.Context
import protocol Smithy.ResponseMessageDeserializer
import protocol SmithySerialization.Codec
import protocol SmithySerialization.DeserializableShape
import SmithyHTTPAPI
@_spi(SmithyReadWrite) import SmithyReadWrite

@_spi(SmithyReadWrite)
public struct SchemaDeserializeMiddleware<OperationStackOutput: DeserializableShape> {
    public var id: String = "Deserialize"
    let codec: any Codec
    let wireResponseErrorClosure: WireResponseErrorClosure<HTTPResponse>

    public init(
        _ codec: any Codec,
        _ wireResponseErrorClosure: @escaping WireResponseErrorClosure<HTTPResponse>
    ) {
        self.codec = codec
        self.wireResponseErrorClosure = wireResponseErrorClosure
    }
}

extension SchemaDeserializeMiddleware: ResponseMessageDeserializer {
    public func deserialize(
        response: HTTPResponse,
        attributes: Context
    ) async throws -> OperationStackOutput {
        if let responseDateString = response.headers.value(for: "Date") {
            let estimatedSkew = getEstimatedSkew(now: Date(), responseDateString: responseDateString)
            attributes.estimatedSkew = estimatedSkew
        }

        // check if the response body was effected by a previous middleware
        if let contextBody = attributes.httpResponse?.body {
            response.body = contextBody
        }

        let copiedResponse = response
        if (200..<300).contains(response.statusCode.rawValue) {
            let deserializer = try codec.makeDeserializer()
            // TODO: wire up response stream to deserializer here
            return try OperationStackOutput.deserialize(deserializer)
        } else {
            // if the response is a stream, we need to cache the stream so that it can be read again
            // error deserialization reads the stream multiple times to first deserialize the protocol error
            // eg. [RestJSONError](https://github.com/awslabs/aws-sdk-swift/blob/d1d18eefb7457ed27d416b372573a1f815004eb1/Sources/Core/AWSClientRuntime/Protocols/RestJSON/RestJSONError.swift#L38,
            // and then the service error eg. [AccountNotFoundException](https://github.com/awslabs/aws-sdk-swift/blob/d1d18eefb7457ed27d416b372573a1f815004eb1/Sources/Services/AWSCloudTrail/models/Models.swift#L62)
            let bodyData = try await copiedResponse.body.readData()
            copiedResponse.body = .data(bodyData)
            throw try await wireResponseErrorClosure(copiedResponse)
        }
    }
}
