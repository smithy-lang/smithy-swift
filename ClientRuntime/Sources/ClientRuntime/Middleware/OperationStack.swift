// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct OperationStack<StackInput: HttpRequestBinding, StackOutput: HttpResponseBinding> {
    
    ///returns the unique id for the operation stack as middleware
    public var id: String
    public var initializeStep: InitializeStep<StackInput>
    public var buildStep: BuildStep
    public var serializeStep: SerializeStep
    public var finalizeStep: FinalizeStep
    public var deserializeStep: DeserializeStep<StackOutput>
    
    public init(id: String) {
        self.id = id
        self.initializeStep = InitializeStep<StackInput>()
        self.serializeStep = SerializeStep()
        self.buildStep = BuildStep()
        self.finalizeStep = FinalizeStep()
        self.deserializeStep = DeserializeStep<StackOutput>()
    }
    
    /// This execute will execute the stack and use your next as the last closure in the chain
    func handleMiddleware<H: Handler>(context: HttpContext,
                                      subject: StackInput,
                                      next: H) -> Result<DeserializeOutput<StackOutput>, Error> where H.Input == SdkHttpRequest,
                                                                                                      H.Output == DeserializeOutput<StackOutput>,
                                                                                                      H.Context == HttpContext {
        // create all the steps to link them as one middleware chain, each step has its own handler to convert the types except the last link in the chain
        let initializeStackStep = MiddlewareStackStep<StackInput,
                                                      SdkHttpRequestBuilder>(stack: initializeStep.eraseToAnyMiddlewareStack(),
                                                                             handler: InitializeStepHandler().eraseToAnyHandler())
        let serializeStackStep = MiddlewareStackStep<SdkHttpRequestBuilder,
                                                     SdkHttpRequestBuilder>(stack: serializeStep.eraseToAnyMiddlewareStack(),
                                                                            handler: SerializeStepHandler().eraseToAnyHandler())
        let buildStackStep = MiddlewareStackStep<SdkHttpRequestBuilder,
                                                 SdkHttpRequestBuilder>(stack: buildStep.eraseToAnyMiddlewareStack(),
                                                                        handler: BuildStepHandler().eraseToAnyHandler())
        let finalizeStackStep = MiddlewareStackStep<SdkHttpRequestBuilder,
                                                    SdkHttpRequest>(stack: finalizeStep.eraseToAnyMiddlewareStack(),
                                                                    handler: FinalizeStepHandler().eraseToAnyHandler())
        //deserialize does not take a handler because its handler is the last handler in the operation which is defined as next inside this function and is wrapped below and added as the last chain in the middleware stack of steps
        let deserializeStackStep = MiddlewareStackStep<SdkHttpRequest,
                                                       DeserializeOutput<StackOutput>>(stack: deserializeStep.eraseToAnyMiddlewareStack())
        let steps = [initializeStackStep.eraseToAnyMiddleware(),
                     serializeStackStep.eraseToAnyMiddleware(),
                     buildStackStep.eraseToAnyMiddleware(),
                     finalizeStackStep.eraseToAnyMiddleware(),
                     deserializeStackStep.eraseToAnyMiddleware()]
        
        let wrappedHandler = StepHandler<SdkHttpRequest, DeserializeOutput<StackOutput>, Any, Any, HttpContext>(next: next.eraseToAnyHandler())
        
        //compose the steps which are each middleware stacks as one big middleware stack chain with a final handler
        let handler = compose(next: wrappedHandler, with: steps)
        
        let result = handler.handle(context: context, input: subject) //kicks off the entire operation of middleware stacks
        
        return result.flatMap { (anyResult) -> Result<DeserializeOutput<StackOutput>, Error> in //have to match the result because types
            if let result = anyResult as? DeserializeOutput<StackOutput> {
                return .success(result)
            } else {
                return .failure(MiddlewareStepError.castingError("casted from operation stack failed"))
            }
        }
    }
    
    /// Compose (wrap) the handler with the given middleware or essentially build out the linked list of middleware
    func compose<H: Handler, M: Middleware>(next: H, with: [M]) -> AnyHandler<H.Input, H.Output, H.Context> where M.MOutput == Any,
                                                                                                                  M.MInput == Any,
                                                                                                                  H.Input == Any,
                                                                                                                  H.Output == Any,
                                                                                                                  H.Context == M.Context {
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
