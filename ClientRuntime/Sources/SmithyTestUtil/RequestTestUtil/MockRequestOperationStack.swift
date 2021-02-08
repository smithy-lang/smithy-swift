// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.
import ClientRuntime

public struct MockRequestOperationStack<StackInput: HttpRequestBinding> {
    
    typealias InitializeStackStep = MiddlewareStackStep<StackInput,
                                                        StackInput>
    typealias SerializeStackStep = MiddlewareStackStep<SerializeStepInput<StackInput>,
                                                       SerializeStepInput<StackInput>>
    typealias BuildStackStep = MiddlewareStackStep<SerializeStepInput<StackInput>,
                                                   SdkHttpRequestBuilder>
    typealias FinalizeStackStep = MiddlewareStackStep<SdkHttpRequestBuilder,
                                                      SdkHttpRequest>
    
    public var id: String
    public var initializeStep: InitializeStep<StackInput>
    public var buildStep: BuildStep<StackInput>
    public var serializeStep: SerializeStep<StackInput>
    public var finalizeStep: FinalizeStep
    
    public init(id: String) {
        self.id = id
        self.initializeStep = InitializeStep<StackInput>()
        self.serializeStep = SerializeStep<StackInput>()
        self.buildStep = BuildStep<StackInput>()
        self.finalizeStep = FinalizeStep()
    }
    
    public mutating func handleMiddleware(context: HttpContext, input: StackInput) -> Result<SdkHttpRequest, Error> {

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
        
        let mockHandler = MockHandler(resultType: { _, input in .success(input) })
        
        let wrappedHandler = StepHandler<SdkHttpRequest,
                                         SdkHttpRequest,
                                         Any,
                                         Any,
                                         HttpContext>(next: mockHandler.eraseToAnyHandler())
        
        // compose the steps which are each middleware stacks as one big middleware stack chain with a final handler
        let handler = OperationStack<StackInput, MockOutput, MockError>.compose(next: wrappedHandler, with: steps)
        
        // kicks off the entire operation of middleware stacks
        let result = handler.handle(context: context, input: input)
        return result.flatMap { (result) -> Result<SdkHttpRequest, Error> in
            if let result = result as? SdkHttpRequest {
                return .success(result)
            } else {
                return .failure(MiddlewareStepError.castingError("casted from operation stack failed," +
                                                                "failed to cast type of Any to type of SdkHttpRequest"))
            }
        }
    }
}
