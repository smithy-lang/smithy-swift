// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct OperationStack<StackOutput: HttpResponseBinding> {
    
    ///returns the unique id for the operation stack as middleware
    public var id: String
    public var initializeStep: InitializeStep<StackOutput>
    public var buildStep: BuildStep<StackOutput>
    public var serializeStep: SerializeStep<StackOutput>
    public var finalizeStep: FinalizeStep<StackOutput>
    public var deserializeStep: DeserializeStep<StackOutput>
    
    public init(id: String) {
        self.id = id
        self.initializeStep = InitializeStep<StackOutput>()
        self.serializeStep = SerializeStep<StackOutput>()
        self.buildStep = BuildStep<StackOutput>()
        self.finalizeStep = FinalizeStep<StackOutput>()
        self.deserializeStep = DeserializeStep<StackOutput>()
    }
    
    /// This execute will execute the stack and use your next as the last closure in the chain
    func handleMiddleware<H: Handler>(context: MiddlewareContext,
                                      subject: SdkHttpRequest,
                                      next: H) -> Result<StackOutput, Error> where H.Input == SdkHttpRequest, H.Output == StackOutput {
        let steps: [AnyMiddleware<SdkHttpRequest, StackOutput>] = [initializeStep.eraseToAnyMiddleware(), serializeStep.eraseToAnyMiddleware(), buildStep.eraseToAnyMiddleware(), finalizeStep.eraseToAnyMiddleware(), deserializeStep.eraseToAnyMiddleware()]
        
        let handler = compose(next: next, with: steps)
        
        let result = handler.handle(context: context, input: subject) //kicks of the entire operation of middleware stacks
        return result
    }
    
    /// Compose (wrap) the handler with the given middleware
    func compose<H: Handler, M: Middleware>(next: H, with: [M]) -> AnyHandler<H.Input, StackOutput> where M.MOutput == StackOutput,
                                                                                                          M.MInput == H.Input,
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
