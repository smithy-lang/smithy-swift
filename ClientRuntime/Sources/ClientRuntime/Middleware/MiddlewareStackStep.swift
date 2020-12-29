// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

//cast output of one middleware stack to input of the next
//pass in Any for first two params to trick the chain into thinking each step input and output are the same
struct MiddlewareStackStep<StepInput, StepOutput>: Middleware {
    var id: String
    typealias MInput = Any
    typealias MOutput = Any
    var stack: AnyMiddlewareStack<StepInput, StepOutput>
    
    init(stack: AnyMiddlewareStack<StepInput, StepOutput>) {
        self.id = stack.id
        self.stack = stack
    }
    
    func handle<H>(context: MiddlewareContext, input: MInput, next: H) -> Result<MInput, Error> where H: Handler,
                                                                                                       MInput == H.Input,
                                                                                                       MOutput == H.Output {
        // compose step handlers and call them with `input` cast to right type
        if let sinput = input as? StepInput{
            let wrapHandler = StepHandler<Any, Any, StepInput, StepOutput>(next: next.eraseToAnyHandler())
            let stepOutput = stack.handle(context: context, input: sinput, next: wrapHandler)
            return stepOutput.map { (output) -> Any in
                output as Any
            }
        }
        else {
            return .failure(MiddlewareStepError.castingError("There was a casting error from middleware input of Any to step input"))
        }
    }
}

struct StepHandler<HandlerInput, HandlerOutput, StepInput, StepOutput>: Handler {
    typealias Input = StepInput
    typealias Output = StepOutput
    let next: AnyHandler<HandlerInput, HandlerOutput>
    func handle(context: MiddlewareContext, input: StepInput) -> Result<StepOutput, Error> {
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
        return .failure(MiddlewareStepError.castingError("failed to caset input to handler input which should be any"))
    }
}
