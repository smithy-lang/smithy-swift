// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Initialize Prepares the input, and sets any default parameters as
/// needed, (e.g. idempotency token, and presigned URLs).
///
/// Takes Input Parameters, and returns result or error.
///
/// Receives result or error from Serialize step.
public struct InitializeStep<StackInput>: MiddlewareStack {
    
    public typealias Context = HttpContext
    
    public var orderedMiddleware: OrderedGroup<StackInput,
                                               SerializeStepInput<StackInput>,
                                               HttpContext> = OrderedGroup<StackInput,
                                                                           SerializeStepInput<StackInput>,
                                                                           HttpContext>()
    
    public var id: String = "InitializeStep"
    
    public typealias MInput = StackInput
    
    public typealias MOutput = SerializeStepInput<StackInput>
    
    public init() {}

}

public struct InitializeStepHandler<StackInput>: Handler {
    
    public typealias Input = StackInput
    
    public typealias Output = SerializeStepInput<StackInput>
    
    public init() {}
    
    public func handle(context: HttpContext, input: Input) -> Result<SerializeStepInput<StackInput>, Error> {
        let serializeInput = SerializeStepInput<StackInput>(operationInput: input)
        return .success(serializeInput)
    }
}
