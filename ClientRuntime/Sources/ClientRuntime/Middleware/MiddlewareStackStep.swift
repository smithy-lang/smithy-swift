// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

//cast output of one middleware stack to input of the next
struct MiddlewareStackStep<MIn, MOut, SInput, SOutput>: Middleware {
    
    var id: String
    typealias MInput = MIn
    typealias MOutput = MOut
    
    var stack: AnyMiddlewareStack<SInput, SOutput>
    init(stack: AnyMiddlewareStack<SInput, SOutput>) {
        self.id = stack.id
        self.stack = stack
    }
    func handle<H>(context: MiddlewareContext, input: MInput, next: H) -> Result<MOutput, Error> where H: Handler,
                                                                                                       MInput == H.Input,
                                                                                                       MOutput == H.Output {
        if let sInput = input as? SInput {
            let wrapHandler = StepHandler(next: next.eraseToAnyHandler())
            let result = stack.handle(context: context, input: sInput, next: wrapHandler)
            return result.flatMap { (sOutput) -> Result<MOutput, Error> in
                if let mOutput = sOutput as? MOutput {
                    return .success(mOutput)
                } else {
                    return .failure(MiddlewareStepError.castingError("There was an error casting the output of one step to the input of the next"))
                }
            }
        }
        return .failure(MiddlewareStepError.castingError("There was an error casting the output of one step to the input of the next"))
    }
    
    struct StepHandler: Handler {
        typealias Input = SInput
        typealias Output = SOutput
        let next: AnyHandler<MInput, MOutput>
        func handle(context: MiddlewareContext, input: SInput) -> Result<SOutput, Error> {
            if let mInput = input as? MInput{
                let result = next.handle(context: context, input: mInput)
                return result.flatMap { (mOut) -> Result<SOutput, Error> in
                    if let sOut = mOut as? SOutput {
                        return .success(sOut)
                    } else {
                        return .failure(MiddlewareStepError.castingError("There was an error casting the output of one step to the input of the next"))
                    }
                }
            }
            return .failure(MiddlewareStepError.castingError("There was an error casting the output of one step to the input of the next"))
        }
    }
    
}




