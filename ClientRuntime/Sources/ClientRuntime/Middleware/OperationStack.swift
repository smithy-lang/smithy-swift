// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct OperationStack<StackInput: HttpRequestBinding,
                             StackOutput: HttpResponseBinding,
                             StackError: HttpResponseBinding> {
    typealias InitializeStackStep = MiddlewareStackStep<StackInput,
                                                        SdkHttpRequestBuilder>
    typealias SerializeStackStep = MiddlewareStackStep<SdkHttpRequestBuilder,
                                                       SdkHttpRequestBuilder>
    typealias BuildStackStep = MiddlewareStackStep<SdkHttpRequestBuilder,
                                                   SdkHttpRequestBuilder>
    typealias FinalizeStackStep = MiddlewareStackStep<SdkHttpRequestBuilder,
                                                      SdkHttpRequest>
    typealias DeserializeStackStep = MiddlewareStackStep<SdkHttpRequest,
                                                         DeserializeOutput<StackOutput, StackError>>
    
    ///returns the unique id for the operation stack as middleware
    public var id: String
    public var initializeStep: InitializeStep<StackInput>
    public var buildStep: BuildStep
    public var serializeStep: SerializeStep
    public var finalizeStep: FinalizeStep
    public var deserializeStep: DeserializeStep<StackOutput, StackError>
    
    public init(id: String) {
        self.id = id
        self.initializeStep = InitializeStep<StackInput>()
        self.serializeStep = SerializeStep()
        self.buildStep = BuildStep()
        self.finalizeStep = FinalizeStep()
        self.deserializeStep = DeserializeStep<StackOutput, StackError>()
    }
    
    /// This function if called adds all default middlewares to a typical sdk operation,
    ///  can optionally call from the service client inside an operation
    public mutating func addDefaultOperationMiddlewares() {
        deserializeStep.intercept(position: .before, middleware: DeserializeMiddleware<StackOutput, StackError>())
    }
    
    /// This execute will execute the stack and use your next as the last closure in the chain
    public func handleMiddleware<H: Handler>(context: HttpContext,
                                             input: StackInput,
                                             next: H) -> SdkResult<StackOutput, StackError> where H.Input == SdkHttpRequest,
                                                                                                  H.Output == DeserializeOutput<StackOutput,
                                                                                                                                StackError>,
                                                                                                  H.Context == HttpContext {
        // create all the steps to link them as one middleware chain, each step has its own handler to convert the
        // types except the last link in the chain
        let initializeStackStep = InitializeStackStep(stack: initializeStep.eraseToAnyMiddlewareStack(),
                                                      handler: InitializeStepHandler().eraseToAnyHandler())
        let serializeStackStep = SerializeStackStep(stack: serializeStep.eraseToAnyMiddlewareStack(),
                                                    handler: SerializeStepHandler().eraseToAnyHandler())
        let buildStackStep = BuildStackStep(stack: buildStep.eraseToAnyMiddlewareStack(),
                                            handler: BuildStepHandler().eraseToAnyHandler())
        let finalizeStackStep = FinalizeStackStep(stack: finalizeStep.eraseToAnyMiddlewareStack(),
                                                  handler: FinalizeStepHandler().eraseToAnyHandler())
        //deserialize does not take a handler because its handler is the last handler in the operation which
        //is defined as next inside this function and is wrapped below and added as the last chain in the
        // middleware stack of steps
        let deserializeStackStep = DeserializeStackStep(stack: deserializeStep.eraseToAnyMiddlewareStack())
        
        let steps = [initializeStackStep.eraseToAnyMiddleware(),
                     serializeStackStep.eraseToAnyMiddleware(),
                     buildStackStep.eraseToAnyMiddleware(),
                     finalizeStackStep.eraseToAnyMiddleware(),
                     deserializeStackStep.eraseToAnyMiddleware()]
        
        let wrappedHandler = StepHandler<SdkHttpRequest,
                                         DeserializeOutput<StackOutput, StackError>,
                                         Any,
                                         Any,
                                         HttpContext>(next: next.eraseToAnyHandler())
        
        //compose the steps which are each middleware stacks as one big middleware stack chain with a final handler
        let handler = compose(next: wrappedHandler, with: steps)
        
        //kicks off the entire operation of middleware stacks
        let result = handler.handle(context: context, input: input)
        
        let castedResult = result.flatMap { (anyResult) -> Result<DeserializeOutput<StackOutput, StackError>,
                                                                  Error> in
            //have to match the result because types
            if let result = anyResult as? DeserializeOutput<StackOutput, StackError> {
                return .success(result)
            } else {
                return .failure(MiddlewareStepError.castingError("casted from operation stack failed, failed to cast type"
                                    + "of Any to type of \(DeserializeOutput<StackOutput, StackError>.self) with a Stack"
                                    + "Output of \(StackOutput.self) and a Stack Error of \(StackError.self)"))
            }
        }
        switch castedResult {
        case .failure(let error):
            return .failure(.unknown(error))
        case .success(let output):
            if let stackError = output.error {
                return .failure(.service(stackError))
            } else {
                return .success(output.output!) //output should not be nil here ever if error is nil
            }
        }
        switch castedResult {
        case .failure(let error):
            return .failure(.unknown(error))
        case .success(let output):
            if let stackError = output.error {
                return .failure(.service(stackError))
            } else {
                return .success(output.output!) //output should not be nil here ever if error is nil
            }
        }
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
