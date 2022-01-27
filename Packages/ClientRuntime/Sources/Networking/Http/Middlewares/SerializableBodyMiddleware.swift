//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct SerializableBodyMiddleware<OperationStackInput: Encodable & Reflection,
                                         OperationStackOutput: HttpResponseBinding,
                                         OperationStackError: HttpResponseBinding>: Middleware {
    public let id: Swift.String = "\(String(describing: OperationStackInput.self))BodyMiddleware"
    
    let alwaysSendBody: Bool
    
    public init(alwaysSendBody: Bool = false) {
        self.alwaysSendBody = alwaysSendBody
    }
    
    public func handle<H>(context: Context,
                  input: SerializeStepInput<OperationStackInput>,
                  next: H) -> Swift.Result<OperationOutput<OperationStackOutput>, MError>
    where H: Handler,
    Self.MInput == H.Input,
    Self.MOutput == H.Output,
    Self.Context == H.Context,
    Self.MError == H.MiddlewareError
    {
        do {
            if try !input.operationInput.allPropertiesAreNull() || alwaysSendBody {
                let encoder = context.getEncoder()
                let data = try encoder.encode(input.operationInput)
                let body = HttpBody.data(data)
                input.builder.withBody(body)
            }
        } catch let err {
            return .failure(.client(ClientError.serializationFailed(err.localizedDescription)))
        }
        return next.handle(context: context, input: input)
    }

    public typealias MInput = SerializeStepInput<OperationStackInput>
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
    public typealias MError = SdkError<OperationStackError>
}
