//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct HeaderMiddleware<OperationStackInput: HeaderProvider, OperationStackOutput>: Middleware {
    public let id: String = "\(String(describing: OperationStackInput.self))HeadersMiddleware"

    public init() {}

    public func handle<H>(context: Context,
                          input: MInput,
                          next: H) async throws -> MOutput
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
              input.builder.withHeaders(input.operationInput.headers)

              return try await next.handle(context: context, input: input)
          }

    public typealias MInput = SerializeStepInput<OperationStackInput>
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
}
