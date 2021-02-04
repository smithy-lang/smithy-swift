// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

// cast output of one middleware stack to input of the next
// pass in Any for middleware input and output to trick the chain into thinking each step input and output are the same
public struct MiddlewareStackStep<StepInput, StepOutput>: Middleware {
    
    public var id: String
    public typealias MInput = Any
    public typealias MOutput = Any
    public typealias Context = HttpContext
    let stack: AnyMiddlewareStack<StepInput, StepOutput, Context>
    let handler: AnyHandler<StepInput, StepOutput, Context>?
    public init(stack: AnyMiddlewareStack<StepInput, StepOutput, Context>,
         handler: AnyHandler<StepInput, StepOutput, Context>? = nil) {
        self.id = stack.id
        self.stack = stack
        self.handler = handler
    }
    
    public func handle<H>(context: Context, input: MInput, next: H) -> Result<MOutput, Error> where H: Handler,
                                                                                             MInput == H.Input,
                                                                                             MOutput == H.Output,
                                                                                             Context == H.Context {
        // compose step handlers and call them with `input` cast to right type
        if let sinput = input as? StepInput {
            // last link in the stack needs to be called and then next inside this link needs to be called with
            // its result. call the stack which will run it to completion through the middleware to the handler
            // given for the step and back up
            if let handler = handler {
                let stepOutput = stack.handle(context: context, input: sinput, next: handler)
                // take the output of the stack and convert it to then call next on the next step and return that
                return stepOutput.flatMap { (nextStepInput) -> Result<MOutput, Error> in
                    return next.handle(context: context, input: nextStepInput)
                }
            } else { // if the handler given is nil then we use the handler of the middleware stack as the handler,
                // this should be the last step in the linked stack of stacks. first wrap it. then kick off the stack.
                let wrappedHandler = StepHandler<MInput,
                                                 MOutput,
                                                 StepInput,
                                                 StepOutput,
                                                 Context>(next: next.eraseToAnyHandler())
                return stack.handle(context: context,
                                    input: sinput,
                                    next: wrappedHandler).map { (stepOutput) -> Any in
                    return stepOutput as Any
                }
            }
            
        } else {
            return .failure(
                MiddlewareStepError.castingError(
                    "There was a casting error from middleware input of Any to step input of type \(StepInput.self)"))
        }
    }
}

/// a struct for casting inner inputs and outputs to outer middleware inputs and outputs or vice versa
///  (from stack input to step input or rervese)
public struct StepHandler<HandlerInput,
                   HandlerOutput,
                   StepInput,
                   StepOutput,
                   Context: MiddlewareContext>: Handler {
    public typealias Input = StepInput
    public typealias Output = StepOutput
    let next: AnyHandler<HandlerInput, HandlerOutput, Context>
    
    public init(next: AnyHandler<HandlerInput, HandlerOutput, Context>) {
        self.next = next
    }
    
    public func handle(context: Context, input: StepInput) -> Result<StepOutput, Error> {
        
        if let input = input as? HandlerInput {
            let result = next.handle(context: context, input: input)
            
            return result.flatMap { (any) -> Result<StepOutput, Error> in
                if let any = any as? StepOutput {
                    return .success(any)
                } else {
                    return .failure(
                        MiddlewareStepError.castingError(
                            "failed to cast any to step output of type \(StepOutput.self) in step handler"))
                }
            }
        }
        return .failure(
            MiddlewareStepError.castingError(
                "failed to cast input of type \(StepInput.self) to handler input which should be any"))
    }
}
