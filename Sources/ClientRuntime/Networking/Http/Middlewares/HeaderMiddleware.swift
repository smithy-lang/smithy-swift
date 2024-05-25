//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyAPI.RequestMessageSerializer
import class SmithyHTTPAPI.SdkHttpRequest
import class SmithyHTTPAPI.SdkHttpRequestBuilder
import class SmithyAPI.OperationContext

public struct HeaderMiddleware<OperationStackInput, OperationStackOutput>: Middleware {
    public let id: String = "\(String(describing: OperationStackInput.self))HeadersMiddleware"

    let headerProvider: HeaderProvider<OperationStackInput>

    public init(_ headerProvider: @escaping HeaderProvider<OperationStackInput>) {
        self.headerProvider = headerProvider
    }

    public func handle<H>(context: Context,
                          input: MInput,
                          next: H) async throws -> MOutput
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
              try apply(input: input.operationInput, builder: input.builder, attributes: context)
              return try await next.handle(context: context, input: input)
          }

    public typealias MInput = SerializeStepInput<OperationStackInput>
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = OperationContext
}

extension HeaderMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = SdkHttpRequest
    public typealias AttributesType = OperationContext

    public func apply(input: OperationStackInput, builder: SdkHttpRequestBuilder, attributes: OperationContext) throws {
        builder.withHeaders(headerProvider(input))
    }
}
