//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI
import SmithyReadWrite
import ClientRuntime

public struct MockDeserializeMiddleware<OperationStackOutput>: Middleware {

    public typealias MockDeserializeMiddlewareCallback =
        (Context, SdkHttpRequest) async throws -> OperationOutput<OperationStackOutput>?

    public var id: String
    let responseClosure: WireResponseOutputClosure<HttpResponse, OperationStackOutput>
    let callback: MockDeserializeMiddlewareCallback?

    public init(id: String, responseClosure: @escaping WireResponseOutputClosure<HttpResponse, OperationStackOutput>, callback: MockDeserializeMiddlewareCallback? = nil) {
        self.id = id
        self.responseClosure = responseClosure
        self.callback = callback
    }

    public func handle<H>(context: Context,
                          input: SdkHttpRequest,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output {

              if let callbackReturnValue = try await callback?(context, input) {
                  return callbackReturnValue
              }

              let response = try await next.handle(context: context, input: input)

              var copiedResponse = response

              let output = try await responseClosure(copiedResponse.httpResponse)
              copiedResponse.output = output

              return copiedResponse

          }

    public typealias MInput = SdkHttpRequest
    public typealias MOutput = OperationOutput<OperationStackOutput>
}

extension MockDeserializeMiddleware: ResponseMessageDeserializer {
    public func deserialize(response: HttpResponse, attributes: Context) async throws -> Result<OperationStackOutput, Error> {
        let output = try await responseClosure(response)
        return .success(output)
    }
}
