// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct ContentTypeMiddleware<OperationStackInput>: Middleware where OperationStackInput: Encodable, OperationStackInput: Reflection {

    public let id: String = "ContentType"

    let contentType: String

    public init(contentType: String) {
        self.contentType = contentType
    }

    public func handle<H>(context: Context,
                          input: SerializeStepInput<OperationStackInput>,
                          next: H) -> Result<SerializeStepInput<OperationStackInput>, Error>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {

        input.builder.withHeader(name: "Content-Type", value: contentType)

        return next.handle(context: context, input: input)
    }

    public typealias MInput = SerializeStepInput<OperationStackInput>
    public typealias MOutput = SerializeStepInput<OperationStackInput>
    public typealias Context = HttpContext
}
