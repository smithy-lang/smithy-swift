//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

typealias PresignerShimHandler = (SdkHttpRequestBuilder) -> Void

struct PresignerShim<OperationStackOutput>: Middleware {
    public let id: String = "PresignerShim"

    private let handler: PresignerShimHandler
    private let output: OperationStackOutput

    init(handler: @escaping PresignerShimHandler, output: OperationStackOutput) {
        self.handler = handler
        self.output = output
    }

    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext

    public func handle<H>(context: HttpContext,
                          input: SdkHttpRequestBuilder,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
          Self.Context == H.Context,
          Self.MInput == H.Input,
          Self.MOutput == H.Output {
              handler(input)
              let httpResponse = HttpResponse(body: .noStream, statusCode: .ok)
              return .init(httpResponse: httpResponse, output: output)
          }
}
