// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

//cast output of one middleware stack to input of the next
//pass in Any for first two params to trick the chain into thinking each step input and output are the same
struct MiddlewareStackStep<StepInput, StepOutput>: Middleware {
    var id: String
    typealias MInput = Any
    typealias MOutput = Any
    typealias Context = HttpContext
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
                //call the stack which will run it to completion through the middleware to the handler given for the step and back up
                let stepOutput = stack.handle(context: context, input: sinput, next: handler)
                // take the output of the stack and convert it to then call next on the next step
                return stepOutput.flatMap { (nextStepInput) -> Result<MInput, Error> in
                    return next.handle(context: context, input: nextStepInput)
                }
            case .after:
                // call the handler first since is the end of the chain
                let result = next.handle(context: context, input: input)
                //cast the success result (i.e. http response) to an http respoonse and add it to the context
                // then call the deserialize stack essentially or the last step in the middleware.
                return result.flatMap { (response) -> Result<MInput, Error> in
                    var copiedContext = context
                    copiedContext.response = response as? HttpResponse
                    return stack.handle(context: copiedContext, input: sinput, next: handler).map { (stepOutput) -> MInput in
                        return stepOutput as MInput
                    }
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
