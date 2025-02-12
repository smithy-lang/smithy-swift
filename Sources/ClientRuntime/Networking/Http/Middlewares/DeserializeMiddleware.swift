//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyHTTPAPI
@_spi(SmithyReadWrite) import SmithyReadWrite
import class Foundation.DateFormatter
import struct Foundation.Locale
import struct Foundation.TimeInterval
import struct Foundation.TimeZone
import struct Foundation.UUID
import class Smithy.Context
import struct Smithy.AttributeKey
import protocol Smithy.ResponseMessageDeserializer

@_spi(SmithyReadWrite)
public struct DeserializeMiddleware<OperationStackOutput> {
    public var id: String = "Deserialize"
    let wireResponseClosure: WireResponseOutputClosure<HTTPResponse, OperationStackOutput>
    let wireResponseErrorClosure: WireResponseErrorClosure<HTTPResponse>
    let operationName: String

    public init(
        _ wireResponseClosure: @escaping WireResponseOutputClosure<HTTPResponse, OperationStackOutput>,
        _ wireResponseErrorClosure: @escaping WireResponseErrorClosure<HTTPResponse>,
        _ operationName: String = "Unsupported"
    ) {
        self.wireResponseClosure = wireResponseClosure
        self.wireResponseErrorClosure = wireResponseErrorClosure
        self.operationName = operationName
    }
}

extension DeserializeMiddleware: ResponseMessageDeserializer {
    public func deserialize(
        response: HTTPResponse,
        attributes: Context
    ) async throws -> OperationStackOutput {
        attributes.set(key: AttributeKey(name: "OperationName"), value: operationName)
        if let responseDateString = response.headers.value(for: "Date") {
            let estimatedSkew = getEstimatedSkew(now: Date(), responseDateString: responseDateString)
            attributes.estimatedSkew = estimatedSkew
        }

        // check if the response body was effected by a previous middleware
        if let contextBody = attributes.httpResponse?.body {
            response.body = contextBody
        }

        let deserializationStart = Date().timeIntervalSince1970

        let copiedResponse = response
        if (200..<300).contains(response.statusCode.rawValue) {
            let deserializedResponse = try await wireResponseClosure(copiedResponse)

            let deserializationEnd = Date().timeIntervalSince1970
            let deserializationElapsedMs = (deserializationEnd - deserializationStart) * 1000.0  // in milliseconds
            DeserializationMetrics.shared.record(time: deserializationElapsedMs, for: operationName)

            return deserializedResponse
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

// Calculates & returns estimated skew.
func getEstimatedSkew(now: Date, responseDateString: String) -> TimeInterval {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
    let responseDate: Date = dateFormatter.date(from: responseDateString) ?? now
    // (Estimated skew) = (Date header from HTTP response) - (client's current time)).
    return responseDate.timeIntervalSince(now)
}
