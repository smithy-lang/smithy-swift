// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.
import ClientRuntime

//this mock middleware operation stack runs all the steps except deserialize so that it returns us the request right before it would essentially be made and then we can compare the request in the test with the given json to ensure accuracy
public struct MockRequestOperationStack<StackInput: HttpRequestBinding> {
    typealias InitializeStackStep = MiddlewareStackStep<StackInput,
                                                        SdkHttpRequestBuilder>
    typealias SerializeStackStep = MiddlewareStackStep<SdkHttpRequestBuilder,
                                                       SdkHttpRequestBuilder>
    typealias BuildStackStep = MiddlewareStackStep<SdkHttpRequestBuilder,
                                                   SdkHttpRequestBuilder>
    typealias FinalizeStackStep = MiddlewareStackStep<SdkHttpRequestBuilder,
                                                      SdkHttpRequest>
    
    ///returns the unique id for the operation stack as middleware
    public var id: String
    public var initializeStep: InitializeStep<StackInput>
    public var buildStep: BuildStep
    public var serializeStep: SerializeStep
    public var finalizeStep: FinalizeStep
    
    public init(id: String) {
        self.id = id
        self.initializeStep = InitializeStep<StackInput>()
        self.serializeStep = SerializeStep()
        self.buildStep = BuildStep()
        self.finalizeStep = FinalizeStep()
    }
    
    /// This execute will execute the stack and use your next as the last closure in the chain
    public func handleMiddleware(context: HttpContext,
                                             input: StackInput) -> Result<SdkHttpRequest, Error> {

        let initializeStackStep = InitializeStackStep(stack: initializeStep.eraseToAnyMiddlewareStack(),
                                                      handler: InitializeStepHandler().eraseToAnyHandler())
        let serializeStackStep = SerializeStackStep(stack: serializeStep.eraseToAnyMiddlewareStack(),
                                                    handler: SerializeStepHandler().eraseToAnyHandler())
        let buildStackStep = BuildStackStep(stack: buildStep.eraseToAnyMiddlewareStack(),
                                            handler: BuildStepHandler().eraseToAnyHandler())
        let finalizeStackStep = FinalizeStackStep(stack: finalizeStep.eraseToAnyMiddlewareStack(),
                                                  handler: FinalizeStepHandler().eraseToAnyHandler())
        
        let steps = [initializeStackStep.eraseToAnyMiddleware(),
                     serializeStackStep.eraseToAnyMiddleware(),
                     buildStackStep.eraseToAnyMiddleware(),
                     finalizeStackStep.eraseToAnyMiddleware()]
        
        let wrappedHandler = StepHandler<SdkHttpRequest,
                                         SdkHttpRequest,
                                         Any,
                                         Any,
                                         HttpContext>(next: MockHandler().eraseToAnyHandler())
        
        //compose the steps which are each middleware stacks as one big middleware stack chain with a final handler
        let handler = compose(next: wrappedHandler, with: steps)
        
        //kicks off the entire operation of middleware stacks
        let result = handler.handle(context: context, input: input)
        
        let castedResult = result.flatMap { (anyResult) -> Result<SdkHttpRequest,
                                                                  Error> in
            //have to match the result because types
            if let result = anyResult as? SdkHttpRequest {
                return .success(result)
            } else {
                return .failure(MiddlewareStepError.castingError("casted from operation stack failed," +
                                                                "failed to cast type of Any to type of " +
                                                                "\(SdkHttpRequest.self)"))
            }
        }
        return castedResult
    }
    
    /// Compose (wrap) the handler with the given middleware or essentially build out the linked list of middleware
    func compose<H: Handler, M: Middleware>(next: H,
                                            with: [M]) -> AnyHandler<H.Input,
                                                                     H.Output,
                                                                     H.Context> where M.MOutput == Any,
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
