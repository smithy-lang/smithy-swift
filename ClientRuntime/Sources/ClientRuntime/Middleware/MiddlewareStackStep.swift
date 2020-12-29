// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

//cast output of one middleware stack to input of the next
//pass in Any for first two params to trick the chain into thinking each step input and output are the same
struct MiddlewareStackStep<StepInput, StepOutput, Context: MiddlewareContext>: Middleware {
    var id: String
    typealias MInput = Any
    typealias MOutput = Any
    let stack: AnyMiddlewareStack<StepInput, StepOutput, Context>
    let handler: AnyHandler<StepInput, StepOutput, Context>
    let position: Position
    init(stack: AnyMiddlewareStack<StepInput, StepOutput, Context>,
         handler: AnyHandler<StepInput, StepOutput, Context>,
         position: Position) {
        self.id = stack.id
        self.stack = stack
        self.handler = handler
        self.position = position
    }
    
    func handle<H>(context: Context, input: MInput, next: H) -> Result<MInput, Error> where H: Handler,
                                                                                                       MInput == H.Input,
    MOutput == H.Output, Context == H.Context {
        // compose step handlers and call them with `input` cast to right type
        if let sinput = input as? StepInput{
            //last link in the stack needs to be called and then next inside this link needs to be called with its result.
            switch position {
            case .before:
                let stepOutput = stack.handle(context: context, input: sinput, next: handler)
                
                let mapped = stepOutput.map { (output) -> Any in
                    output as Any
                }
                
                switch mapped {
                case .failure(let error):
                    return .failure(error) //if one step fails why even go to the next step, just send back failure right here
                case .success(let nextStepInput):
                    return next.handle(context: context, input: nextStepInput)
                }
            case .after:
                let wrappedHandler = StepHandler<MInput, MOutput, StepInput, StepOutput, Context>(next: next.eraseToAnyHandler())
                let result = stack.handle(context: context, input: sinput, next: wrappedHandler)
                return result.map { (stepOutput) -> Any in
                    stepOutput as Any
                }
            }
        }
        else {
            return .failure(MiddlewareStepError.castingError("There was a casting error from middleware input of Any to step input"))
        }
    }
}

struct StepHandler<HandlerInput, HandlerOutput, StepInput, StepOutput, Context: MiddlewareContext>: Handler {
    typealias Input = StepInput
    typealias Output = StepOutput
    let next: AnyHandler<HandlerInput, HandlerOutput, Context>
    
    func handle(context: Context, input: StepInput) -> Result<StepOutput, Error> {
       
        if let input = input as? HandlerInput {
        let result = next.handle(context: context, input: input)
        
        return result.flatMap { (any) -> Result<StepOutput, Error> in
            if let any = any as? StepOutput {
                return .success(any)
            } else {
                return .failure(MiddlewareStepError.castingError("failed to cast any to step output in step handler"))
            }
        }
        }
        return .failure(MiddlewareStepError.castingError("failed to cast input to handler input which should be any"))
    }
}
