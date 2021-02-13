// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Initialize Prepares the input, and sets any default parameters as
/// needed, (e.g. idempotency token, and presigned URLs).
///
/// Takes Input Parameters, and returns result or error.
///
/// Receives result or error from Serialize step.
public struct InitializeStep<OperationStackInput>: MiddlewareStack where OperationStackInput: Encodable, OperationStackInput: Reflection {
    
    public typealias Context = HttpContext
    
    public var orderedMiddleware: OrderedGroup<OperationStackInput,
                                               SerializeStepInput<OperationStackInput>,
                                               HttpContext> = OrderedGroup<OperationStackInput,
                                                                           SerializeStepInput<OperationStackInput>,
                                                                           HttpContext>()
    
    public var id: String = "InitializeStep"
    
    public typealias MInput = OperationStackInput
    
    public typealias MOutput = SerializeStepInput<OperationStackInput>
    
    public init() {}

}

public struct InitializeStepHandler<OperationStackInput>: Handler where OperationStackInput: Encodable, OperationStackInput: Reflection {
    
    public typealias Input = OperationStackInput
    
    public typealias Output = SerializeStepInput<OperationStackInput>
    
    public init() {}
    
    public func handle(context: HttpContext, input: Input) -> Result<SerializeStepInput<OperationStackInput>, Error> {
        let serializeInput = SerializeStepInput<OperationStackInput>(operationInput: input)
        return .success(serializeInput)
    }
}
