// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct ContentTypeMiddleware<OperationStackInput,
                                    OperationStackOutput: HttpResponseBinding,
                                    OperationStackError: HttpResponseBinding>: Middleware {

    public let id: String = "ContentType"

    let contentType: String

    public init(contentType: String) {
        self.contentType = contentType
    }

    public func handle<H>(context: Context,
                          input: SerializeStepInput<OperationStackInput>,
                          next: H) -> Result<OperationOutput<OperationStackOutput>, MError>
    where H: Handler,
    Self.MInput == H.Input,
    Self.MOutput == H.Output,
    Self.Context == H.Context,
    Self.MError == H.MiddlewareError {
        
        if !input.builder.headers.exists(name: "Content-Type") {
            input.builder.withHeader(name: "Content-Type", value: contentType)
        }
        
        return next.handle(context: context, input: input)
    }

    public typealias MInput = SerializeStepInput<OperationStackInput>
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
    public typealias MError = SdkError<OperationStackError>
}
