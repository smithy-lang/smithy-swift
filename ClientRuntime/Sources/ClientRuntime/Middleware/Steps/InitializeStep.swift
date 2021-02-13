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
                                E: HttpResponseBinding> = MiddlewareStep<I, OperationOutput<O, E>>

public struct InitializeStepHandler<OperationStackInput: Encodable & Reflection,
                                    OperationStackOutput: HttpResponseBinding,
                                    OperationStackError: HttpResponseBinding,
                                    H: Handler>: Handler where H.Context == HttpContext,
                                                               H.Input == SerializeStepInput<OperationStackInput>,
                                                               H.Output == OperationOutput<OperationStackOutput, OperationStackError> {
    
    public typealias Input = OperationStackInput
    
    public typealias Output = OperationOutput<OperationStackOutput, OperationStackError>
    let inner: H
    
    public init(inner: H) {
        self.inner = inner
    }
    
    public func handle(context: HttpContext, input: Input) -> Result<Output, Error> {
        let serializeInput = SerializeStepInput<OperationStackInput>(operationInput: input)
        
        return inner.handle(context: context, input: serializeInput)
    }
}
