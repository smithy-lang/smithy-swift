// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct DeserializeMiddleware<Output: HttpResponseBinding,
                                    OutputError: HttpResponseBinding>: Middleware {

    public var id: String = "Deserialize"
    public init() {}
    public func handle<H>(context: HttpContext,
                          input: SdkHttpRequest,
                          next: H) async throws -> OperationOutput<Output>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {

          let decoder = context.getDecoder()
          let response = try await next.handle(context: context, input: input) // call handler to get http response
          var copiedResponse = response
          if (200..<300).contains(response.httpResponse.statusCode.rawValue) {
              let output = try Output(httpResponse: copiedResponse.httpResponse, decoder: decoder)
              copiedResponse.output = output
              return copiedResponse
          } else {
              let error = try OutputError(httpResponse: copiedResponse.httpResponse, decoder: decoder)
              throw SdkError.service(error, copiedResponse.httpResponse)
          }
    }

    public typealias MInput = SdkHttpRequest
    public typealias MOutput = OperationOutput<Output>
    public typealias Context = HttpContext

}
