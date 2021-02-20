// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Initialize Prepares the input, and sets any default parameters as
/// needed, (e.g. idempotency token, and presigned URLs).
///
/// Takes Input Parameters, and returns result or error.
///
/// Receives result or error from Serialize step.
public typealias InitializeStep<I: Encodable & Reflection,
                                O: HttpResponseBinding,
                                E: HttpResponseBinding> = MiddlewareStep<HttpContext,
                                                                         I,
                                                                         OperationOutput<O, E>>

public let InitializeStepId = "Initialize"

public struct InitializeStepHandler<OperationStackInput: Encodable & Reflection,
                                    OperationStackOutput: HttpResponseBinding,
                                    OperationStackError: HttpResponseBinding,
                                    H: Handler>: Handler where H.Context == HttpContext,
                                                               H.Input == SerializeStepInput<OperationStackInput>,
                                                               H.Output == OperationOutput<OperationStackOutput,
                                                                                           OperationStackError> {
    
    public typealias Input = OperationStackInput
    
    public typealias Output = OperationOutput<OperationStackOutput, OperationStackError>
    let handler: H
    
    public init(handler: H) {
        self.handler = handler
    }
    
    public func handle(context: HttpContext, input: Input) -> Result<Output, Error> {
        let serializeInput = SerializeStepInput<OperationStackInput>(operationInput: input)
        
        return handler.handle(context: context, input: serializeInput)
    }
}
