//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct QueryItemMiddleware<OperationStackInput, OperationStackOutput>: Middleware {
    public let id: String = "\(String(describing: OperationStackInput.self))QueryItemMiddleware"

    let queryItemProvider: QueryItemProvider<OperationStackInput>

    public init(_ queryItemProvider: @escaping QueryItemProvider<OperationStackInput>) {
        self.queryItemProvider = queryItemProvider
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
    public typealias Context = HttpContext
}

extension QueryItemMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = SdkHttpRequest
    public typealias AttributesType = HttpContext

    public func apply(input: OperationStackInput, builder: SdkHttpRequestBuilder, attributes: HttpContext) throws {
        for queryItem in try queryItemProvider(input) {
            builder.withQueryItem(queryItem)
        }
    }
}
