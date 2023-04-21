//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

public struct MockSerializeStreamMiddleware: Middleware {
    public func handle<H>(context: HttpContext,
                          input: SerializeStepInput<MockStreamInput>,
                          next: H) async throws -> OperationOutput<MockOutput>
    where H: Handler, HttpContext == H.Context,
          SerializeStepInput<MockStreamInput> == H.Input,
          OperationOutput<MockOutput> == H.Output {
              input.builder.withBody(.init(byteStream: input.operationInput.body))
              return try await next.handle(context: context, input: input)
    }

    public init() {}

    public var id: String = "MockSerializeStreamMiddleware"

    public typealias MInput = SerializeStepInput<MockStreamInput>

    public typealias MOutput = OperationOutput<MockOutput>

    public typealias Context = HttpContext
}
