//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import protocol Smithy.ResponseMessageDeserializer
import SmithyReadWrite
import SmithyHTTPAPI

public struct DeserializeMiddleware<OperationStackOutput>: Middleware {
    public var id: String = "Deserialize"
    let wireResponseClosure: WireResponseOutputClosure<HttpResponse, OperationStackOutput>
    let wireResponseErrorClosure: WireResponseErrorClosure<HttpResponse>

    public init(
        _ wireResponseClosure: @escaping WireResponseOutputClosure<HttpResponse, OperationStackOutput>,
        _ wireResponseErrorClosure: @escaping WireResponseErrorClosure<HttpResponse>
    ) {
        self.wireResponseClosure = wireResponseClosure
        self.wireResponseErrorClosure = wireResponseErrorClosure
    }
    public func handle<H>(context: Context,
                          input: SdkHttpRequest,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
            Self.MInput == H.Input,
            Self.MOutput == H.Output {

            var response = try await next.handle(context: context, input: input) // call handler to get http response

            if let responseDateString = response.httpResponse.headers.value(for: "Date") {
                let estimatedSkew = getEstimatedSkew(now: Date(), responseDateString: responseDateString)
                context.estimatedSkew = estimatedSkew
            }

            let result = try await deserialize(response: response.httpResponse, attributes: context)

            switch result {
            case let .success(output):
                response.output = output
            case let .failure(error):
                throw error
            }

            return response
    }

    public typealias MInput = SdkHttpRequest
    public typealias MOutput = OperationOutput<OperationStackOutput>
}

extension DeserializeMiddleware: ResponseMessageDeserializer {
    public func deserialize(
        response: HttpResponse,
        attributes: Context
    ) async throws -> Result<OperationStackOutput, Error> {
        // check if the response body was effected by a previous middleware
        if let contextBody = attributes.httpResponse?.body {
            response.body = contextBody
        }

        let copiedResponse = response
        if (200..<300).contains(response.statusCode.rawValue) {
            return .success(try await wireResponseClosure(copiedResponse))
        } else {
            // if the response is a stream, we need to cache the stream so that it can be read again
            // error deserialization reads the stream multiple times to first deserialize the protocol error
            // eg. [RestJSONError](https://github.com/awslabs/aws-sdk-swift/blob/d1d18eefb7457ed27d416b372573a1f815004eb1/Sources/Core/AWSClientRuntime/Protocols/RestJSON/RestJSONError.swift#L38,
            // and then the service error eg. [AccountNotFoundException](https://github.com/awslabs/aws-sdk-swift/blob/d1d18eefb7457ed27d416b372573a1f815004eb1/Sources/Services/AWSCloudTrail/models/Models.swift#L62)
            let bodyData = try await copiedResponse.body.readData()
            copiedResponse.body = .data(bodyData)
            return .failure(try await wireResponseErrorClosure(copiedResponse))
        }
    }
}
