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

            let response = try await next.handle(context: context, input: input)
            var copiedResponse = response

            // Wait for status code of http response to be finalized; i.e., not [100, 200).
            let code = await response.httpResponse.getFinalStatusCode()

            if (200..<300).contains(code) {
                let output = try await httpResponseClosure(copiedResponse.httpResponse)
                copiedResponse.output = output
                return copiedResponse
            } else {
                // if the response is a stream, we need to cache the stream so that it can be read again
                // error deserialization reads the stream multiple times to first deserialize the protocol error
                // eg. [RestJSONError](https://github.com/awslabs/aws-sdk-swift/blob/d1d18eefb7457ed27d416b372573a1f815004eb1/Sources/Core/AWSClientRuntime/Protocols/RestJSON/RestJSONError.swift#L38,
                // and then the service error eg. [AccountNotFoundException](https://github.com/awslabs/aws-sdk-swift/blob/d1d18eefb7457ed27d416b372573a1f815004eb1/Sources/Services/AWSCloudTrail/models/Models.swift#L62)
                let bodyData = try await copiedResponse.httpResponse.body.readData()
                await copiedResponse.httpResponse.setBody(newBody: .data(bodyData))
                throw try await httpResponseErrorClosure(copiedResponse.httpResponse)
          }
    }

    public typealias MInput = SdkHttpRequest
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext

}
