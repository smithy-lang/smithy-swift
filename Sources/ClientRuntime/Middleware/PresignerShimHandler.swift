//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

typealias PresignerShimHandler = (SdkHttpRequestBuilder) -> Void

struct PresignerShim<OperationStackOutput: HttpResponseBinding,
                     OperationStackError: HttpResponseErrorBinding>: Middleware {
    public let id: String = "PresignerShim"

    private let handler: PresignerShimHandler

    init(handler: @escaping PresignerShimHandler) {
        self.handler = handler
    }

    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
    public typealias MError = OperationStackError

    public func handle<H>(context: HttpContext,
                          input: SdkHttpRequestBuilder,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
          Self.Context == H.Context,
          Self.MInput == H.Input,
          Self.MOutput == H.Output {
              handler(input)
              let httpResponse = HttpResponse(body: .none, statusCode: .ok)
              do {
                  let output: OperationStackOutput? = try await OperationStackOutput(
                    httpResponse: httpResponse,
                    decoder: nil)
                  return .init(httpResponse: httpResponse, output: output)
              } catch {
                  throw ClientError.unknownError("PresignerShimHandler: This code should not execute")
              }
          }
}
