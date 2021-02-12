// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.
import ClientRuntime
// TO BE DELETED, once we update the code generation
public struct MockRequestOperationStack<OperationStackInput> where OperationStackInput: Encodable, OperationStackInput: Reflection {
    typealias InitializeStackStep = MiddlewareStackStep<OperationStackInput,
                                                        SerializeStepInput<OperationStackInput>>
    typealias SerializeStackStep = MiddlewareStackStep<SerializeStepInput<OperationStackInput>,
                                                       SerializeStepInput<OperationStackInput>>
    typealias BuildStackStep = MiddlewareStackStep<SerializeStepInput<OperationStackInput>,
                                                   SdkHttpRequestBuilder>
    typealias FinalizeStackStep = MiddlewareStackStep<SdkHttpRequestBuilder,
                                                      SdkHttpRequest>
    
    public var id: String
    public var initializeStep: InitializeStep<OperationStackInput>
    public var buildStep: BuildStep<OperationStackInput>
    public var serializeStep: SerializeStep<OperationStackInput>
    public var finalizeStep: FinalizeStep
    
    public init(id: String) {
        self.id = id
        self.initializeStep = InitializeStep<OperationStackInput>()
        self.serializeStep = SerializeStep<OperationStackInput>()
        self.buildStep = BuildStep<OperationStackInput>()
        self.finalizeStep = FinalizeStep()
    }
    
    public mutating func handleMiddleware(context: HttpContext, input: OperationStackInput) -> Result<SdkHttpRequest, Error> {

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
        
        let mockHandler = LegacyMockHandler(resultType: { _, input in .success(input) })
        
        let wrappedHandler = StepHandler<SdkHttpRequest,
                                         SdkHttpRequest,
                                         Any,
                                         Any,
                                         HttpContext>(next: mockHandler.eraseToAnyHandler())
        
        // compose the steps which are each middleware stacks as one big middleware stack chain with a final handler
        let handler = OperationStack<OperationStackInput, MockOutput, MockMiddlewareError>.compose(next: wrappedHandler, with: steps)
        
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

// This will also be removed in the near future
public struct LegacyMockHandler: Handler {
    public typealias Input = SdkHttpRequest
    public typealias Output = SdkHttpRequest
    let resultType: (_ context: HttpContext, _ input: Input) -> Result<SdkHttpRequest, Error>
    public func handle(context: HttpContext, input: Input) -> Result<SdkHttpRequest, Error> {
        return resultType(context, input)
    }
}
