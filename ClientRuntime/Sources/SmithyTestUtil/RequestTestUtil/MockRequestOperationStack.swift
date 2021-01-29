// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.
import ClientRuntime

public struct MockRequestOperationStack<StackInput: HttpRequestBinding> {
    typealias InitializeStackStep = MiddlewareStackStep<StackInput,
                                                        SdkHttpRequestBuilder>
    typealias SerializeStackStep = MiddlewareStackStep<SdkHttpRequestBuilder,
                                                       SdkHttpRequestBuilder>
    typealias BuildStackStep = MiddlewareStackStep<SdkHttpRequestBuilder,
                                                   SdkHttpRequestBuilder>
    typealias FinalizeStackStep = MiddlewareStackStep<SdkHttpRequestBuilder,
                                                      SdkHttpRequest>
    
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
                                         HttpContext>(next: MockHandlerAlwaysSucceeds().eraseToAnyHandler())
        
        let handler = compose(next: wrappedHandler, with: steps)
        
        let result = handler.handle(context: context, input: input)
        
        let castedResult = result.flatMap { (anyResult) -> Result<SdkHttpRequest,
                                                                  Error> in
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
    
    func compose<H: Handler, M: Middleware>(next handler: H,
                                            with middlewares: [M]) -> AnyHandler<H.Input,
                                                                     H.Output,
                                                                     H.Context> where M.MOutput == Any,
                                                                                      M.MInput == Any,
                                                                                      H.Input == Any,
                                                                                      H.Output == Any,
                                                                                      H.Context == M.Context {
        guard !middlewares.isEmpty else {
            return handler.eraseToAnyHandler()
        }
        
        let count = middlewares.count
        let lastMiddleware = middlewares[count - 1]
        var composedHandler = ComposedHandler(handler, lastMiddleware)
        let secondToLastIndex = count - 2
        let reversedCollection = (0...secondToLastIndex).reversed()
        for index in reversedCollection {
            composedHandler = ComposedHandler(composedHandler, middlewares[index])
        }
        
        return composedHandler.eraseToAnyHandler()
    }
}
