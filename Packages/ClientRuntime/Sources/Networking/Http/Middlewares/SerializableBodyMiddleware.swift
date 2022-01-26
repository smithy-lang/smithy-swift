//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct SerializableBodyMiddleware<OperationStackInput: Encodable & Reflection,
                                         OperationStackOutput: HttpResponseBinding,
                                         OperationStackError: HttpResponseBinding>: ClientRuntime.Middleware {
    public let id: Swift.String = "\(String(describing: OperationStackInput.self))BodyMiddleware"

    public init() {}

    public func handle<H>(context: Context,
                  input: ClientRuntime.SerializeStepInput<OperationStackInput>,
                  next: H) -> Swift.Result<ClientRuntime.OperationOutput<OperationStackOutput>, MError>
    where H: Handler,
    Self.MInput == H.Input,
    Self.MOutput == H.Output,
    Self.Context == H.Context,
    Self.MError == H.MiddlewareError
    {
        do {
            if try !input.operationInput.allPropertiesAreNull() {
                let encoder = context.getEncoder()
                let data = try encoder.encode(input.operationInput)
                let body = ClientRuntime.HttpBody.data(data)
                input.builder.withBody(body)
            }
        } catch let err {
            return .failure(.client(ClientRuntime.ClientError.serializationFailed(err.localizedDescription)))
        }
        return next.handle(context: context, input: input)
    }

    public typealias MInput = ClientRuntime.SerializeStepInput<OperationStackInput>
    public typealias MOutput = ClientRuntime.OperationOutput<OperationStackOutput>
    public typealias Context = ClientRuntime.HttpContext
    public typealias MError = ClientRuntime.SdkError<OperationStackError>
}
