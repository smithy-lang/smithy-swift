//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct DeserializeMiddleware<Output>: Middleware {
    public var id: String = "Deserialize"
    let outputBinding: HTTPResponseBinding<Output>
    let outputErrorBinding: HttpResponseErrorBinding

    public init(
        outputBinding: @escaping HTTPResponseBinding<Output>,
        outputErrorBinding: @escaping HttpResponseErrorBinding
    ) {
        self.outputBinding = outputBinding
        self.outputErrorBinding = outputErrorBinding
    }
    public func handle<H>(context: HttpContext,
                          input: SdkHttpRequest,
                          next: H) async throws -> OperationOutput<Output>
    where H: Handler,
            Self.MInput == H.Input,
            Self.MOutput == H.Output,
            Self.Context == H.Context {

            let response = try await next.handle(context: context, input: input) // call handler to get http response
            var copiedResponse = response
            if (200..<300).contains(response.httpResponse.statusCode.rawValue) {
                let output = try await outputBinding(response.httpResponse)
                copiedResponse.output = output
                return copiedResponse
            } else {
                // if the response is a stream, we need to cache the stream so that it can be read again
                // error deserialization reads the stream multiple times to first deserialize the protocol error
                // eg. [RestJSONError](https://github.com/awslabs/aws-sdk-swift/blob/d1d18eefb7457ed27d416b372573a1f815004eb1/Sources/Core/AWSClientRuntime/Protocols/RestJSON/RestJSONError.swift#L38,
                // and then the service error eg. [AccountNotFoundException](https://github.com/awslabs/aws-sdk-swift/blob/d1d18eefb7457ed27d416b372573a1f815004eb1/Sources/Services/AWSCloudTrail/models/Models.swift#L62)
                let bodyData = try await copiedResponse.httpResponse.body.readData()
                copiedResponse.httpResponse.body = .data(bodyData)
                throw try await outputErrorBinding(copiedResponse.httpResponse)
          }
    }

    public typealias MInput = SdkHttpRequest
    public typealias MOutput = OperationOutput<Output>
    public typealias Context = HttpContext

}
