// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct OperationStack<StackInput: HttpRequestBinding, StackOutput: HttpResponseBinding> {
    
    ///returns the unique id for the operation stack as middleware
    public var id: String
    public var initializeStep: InitializeStep
    public var buildStep: BuildStep
    public var serializeStep: SerializeStep
    public var finalizeStep: FinalizeStep
    public var deserializeStep: DeserializeStep
    
    public init(id: String,
                initializeStep: InitializeStep,
                serializeStep: SerializeStep,
                buildStep: BuildStep,
                finalizeStep: FinalizeStep,
                deserializeStep: DeserializeStep) {
        self.id = id
        self.initializeStep = initializeStep
        self.serializeStep = serializeStep
        self.buildStep = buildStep
        self.finalizeStep = finalizeStep
        self.deserializeStep = deserializeStep
    }
    
    /// This execute will execute the stack and use your next as the last closure in the chain
    func handleMiddleware<H: Handler>(context: MiddlewareContext,
                                      subject: StackInput,
                                      next: H) -> Result<StackOutput, Error> where H.Input == StackInput, H.Output == StackOutput {
        let initializeStackStep = MiddlewareStackStep<StackInput,
                                                      StackOutput,
                                                      Any,
                                                      Any>(stack: initializeStep.eraseToAnyMiddlewareStack())
        let serializeStackStep = MiddlewareStackStep<StackInput,
                                                     StackOutput,
                                                     Any,
                                                     Any>(stack: serializeStep.eraseToAnyMiddlewareStack())
        let buildStackStep = MiddlewareStackStep<StackInput,
                                                 StackOutput,
                                                 Any,
                                                 Any>(stack: buildStep.eraseToAnyMiddlewareStack())
        let finalizeStackStep = MiddlewareStackStep<StackInput,
                                                    StackOutput,
                                                    Any,
                                                    Any>(stack: finalizeStep.eraseToAnyMiddlewareStack())
        
        let deserializeStackStep = MiddlewareStackStep<StackInput,
                                                       StackOutput,
                                                       Any,
                                                       Any>(stack: deserializeStep.eraseToAnyMiddlewareStack())
        
        let handler = compose(next: next, with: initializeStackStep, serializeStackStep, buildStackStep, finalizeStackStep, deserializeStackStep)

        let result = handler.handle(context: context, input: subject) //kicks of the entire operation of middleware stacks
        return result
    }
    
    /// Compose (wrap) the handler with the given middleware
    func compose<H: Handler, M: Middleware>(next: H, with: M...) -> AnyHandler<StackInput, StackOutput> where M.MInput == StackInput,
                                                                                                              M.MOutput == StackOutput,
                                                                                                              H.Input == StackInput,
                                                                                                              H.Output == StackOutput{
        if with.isEmpty {
            return next.eraseToAnyHandler()
        }
        
        let count = with.count

        var handler = ComposedHandler(next, with[count-1])
        let reversedCollection = (0...(count-2)).reversed()
        for index in reversedCollection {
            handler = ComposedHandler(handler, with[index])
        }
        
        return handler.eraseToAnyHandler()
    }
}
