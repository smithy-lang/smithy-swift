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
                                      next: H) -> Result<StackOutput, Error> where H.Input == SdkHttpRequest,
                                                                                   H.Output == HttpResponse,
                                                                                   H.Context == HttpContext {
        let initializeStackStep = MiddlewareStackStep<StackInput,
                                                      SdkHttpRequestBuilder,
                                                      HttpContext>(stack: initializeStep.eraseToAnyMiddlewareStack())
        let serializeStackStep = MiddlewareStackStep<SdkHttpRequestBuilder,
                                                     SdkHttpRequestBuilder,
                                                     HttpContext>(stack: serializeStep.eraseToAnyMiddlewareStack())
        let buildStackStep = MiddlewareStackStep<SdkHttpRequestBuilder,
                                                 SdkHttpRequestBuilder,
                                                 HttpContext>(stack: buildStep.eraseToAnyMiddlewareStack())
        let finalizeStackStep = MiddlewareStackStep<SdkHttpRequestBuilder,
                                                    SdkHttpRequest,
                                                    HttpContext>(stack: finalizeStep.eraseToAnyMiddlewareStack())
        let deserializeStackStep = MiddlewareStackStep<SdkHttpRequest,
                                                       StackOutput,
                                                       HttpContext>(stack: deserializeStep.eraseToAnyMiddlewareStack())
        let steps = [initializeStackStep.eraseToAnyMiddleware(),
                     serializeStackStep.eraseToAnyMiddleware(),
                     buildStackStep.eraseToAnyMiddleware(),
                     finalizeStackStep.eraseToAnyMiddleware(),
                     deserializeStackStep.eraseToAnyMiddleware()]
        
        let wrappedHandler = StepHandler<SdkHttpRequest, HttpResponse, Any, Any, HttpContext>(next: next.eraseToAnyHandler())
        
        let handler = compose(next: wrappedHandler, with: steps)
        
        let result = handler.handle(context: context, input: subject) //kicks of the entire operation of middleware stacks
    
        return result.flatMap { (anyResult) -> Result<StackOutput, Error> in
            if let result = anyResult as? StackOutput {
                return .success(result)
            } else {
                return .failure(MiddlewareStepError.castingError("casted from operation stack failed"))
            }
        }
    }
    
    /// Compose (wrap) the handler with the given middleware
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
