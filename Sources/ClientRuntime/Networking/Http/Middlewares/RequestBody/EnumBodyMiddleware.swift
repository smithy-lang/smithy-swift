//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

public struct EnumBodyMiddleware<OperationStackInput,
                                 OperationStackOutput,
                                 Primitive: RawRepresentable>: Middleware where Primitive.RawValue == String {
    public let id: Swift.String = "EnumBodyMiddleware"

    let keyPath: KeyPath<OperationStackInput, Primitive?>

    public init(keyPath: KeyPath<OperationStackInput, Primitive?>) {
        self.keyPath = keyPath
    }

    public func handle<H>(context: Context,
                          input: SerializeStepInput<OperationStackInput>,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
              let bodyString = input.operationInput[keyPath: keyPath]?.rawValue ?? ""
              let body = HttpBody.data(Data(bodyString.utf8))
              input.builder.withBody(body)
              return try await next.handle(context: context, input: input)
          }

    public typealias MInput = SerializeStepInput<OperationStackInput>
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
}
