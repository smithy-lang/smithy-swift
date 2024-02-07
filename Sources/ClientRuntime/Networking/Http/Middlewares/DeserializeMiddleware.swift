//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct DeserializeMiddleware<OperationStackOutput>: Middleware {
    public var id: String = "Deserialize"
    let httpResponseClosure: HTTPResponseClosure<OperationStackOutput>
    let httpResponseErrorClosure: HTTPResponseErrorClosure

    public init(
        _ httpResponseClosure: @escaping HTTPResponseClosure<OperationStackOutput>,
        _ httpResponseErrorClosure: @escaping HTTPResponseErrorClosure
    ) {
        self.httpResponseClosure = httpResponseClosure
        self.httpResponseErrorClosure = httpResponseErrorClosure
    }
    public func handle<H>(context: HttpContext,
                          input: SdkHttpRequest,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
            Self.MInput == H.Input,
            Self.MOutput == H.Output,
            Self.Context == H.Context {

//            let httpResponse: HttpResponse
//            let response: OperationOutput<OperationStackOutput>
//            if let existingResponse = context.response {
//                httpResponse = existingResponse
//                guard let output = context.attributes.get(key: AttributeKey<OperationStackOutput>(name: "output")) else {
//                    throw ClientError.dataNotFound("Response was corrupted!")
//                }
//                response = OperationOutput(httpResponse: httpResponse, output: output)
//            } else {
//                response = try await next.handle(context: context, input: input) // call handler to get http response
//                httpResponse = response.httpResponse
//            }

            let response = try await next.handle(context: context, input: input) // call handler to get http response
//            context.response = response.httpResponse

            if context.attributes.contains(key: AttributeKey<ByteStream>(name: "stream")) {
                if let validatingStream = context.attributes.get(key: AttributeKey<ByteStream>(name: "stream")) {
                    response.httpResponse.body = validatingStream

                }
            }

            var copiedResponse = response
            if (200..<300).contains(response.httpResponse.statusCode.rawValue) {
                let output = try await httpResponseClosure(copiedResponse.httpResponse)
                copiedResponse.output = output
                return copiedResponse
            } else {
                // if the response is a stream, we need to cache the stream so that it can be read again
                // error deserialization reads the stream multiple times to first deserialize the protocol error
                // eg. [RestJSONError](https://github.com/awslabs/aws-sdk-swift/blob/d1d18eefb7457ed27d416b372573a1f815004eb1/Sources/Core/AWSClientRuntime/Protocols/RestJSON/RestJSONError.swift#L38,
                // and then the service error eg. [AccountNotFoundException](https://github.com/awslabs/aws-sdk-swift/blob/d1d18eefb7457ed27d416b372573a1f815004eb1/Sources/Services/AWSCloudTrail/models/Models.swift#L62)
                let bodyData = try await copiedResponse.httpResponse.body.readData()
                copiedResponse.httpResponse.body = .data(bodyData)
                throw try await httpResponseErrorClosure(copiedResponse.httpResponse)
          }
    }

    public typealias MInput = SdkHttpRequest
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext

}
