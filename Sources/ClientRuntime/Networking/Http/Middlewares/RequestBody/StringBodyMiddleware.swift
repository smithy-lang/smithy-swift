//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

public struct StringBodyMiddleware<OperationStackInput, OperationStackOutput>: Middleware {
    public let id: Swift.String = "\(OperationStackInput.self)StringBodyMiddleware"

    let keyPath: KeyPath<OperationStackInput, String?>

    public init(keyPath: KeyPath<OperationStackInput, String?>) {
        self.keyPath = keyPath
    }

    public func handle<H>(context: Context,
                          input: SerializeStepInput<OperationStackInput>,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
              let body = HttpBody.data(Data((input.operationInput[keyPath: keyPath] ?? "").utf8))
              input.builder.withBody(body)
              return try await next.handle(context: context, input: input)
          }

    public typealias MInput = SerializeStepInput<OperationStackInput>
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
}
