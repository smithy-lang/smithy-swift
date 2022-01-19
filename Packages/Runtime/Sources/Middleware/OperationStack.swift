// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct OperationStack<OperationStackInput: Encodable & Reflection,
                             OperationStackOutput: HttpResponseBinding,
                             OperationStackError: HttpResponseBinding> {
    
    /// returns the unique id for the operation stack as middleware
    public var id: String
    public var initializeStep: InitializeStep<OperationStackInput, OperationStackOutput, OperationStackError>
    public var serializeStep: SerializeStep<OperationStackInput, OperationStackOutput, OperationStackError>
    public var buildStep: BuildStep<OperationStackOutput, OperationStackError>
    public var finalizeStep: FinalizeStep<OperationStackOutput, OperationStackError>
    public var deserializeStep: DeserializeStep<OperationStackOutput, OperationStackError>
    
    public init(id: String) {
        self.id = id
        self.initializeStep = InitializeStep<OperationStackInput,
                                             OperationStackOutput,
                                             OperationStackError>(id: InitializeStepId)
        self.serializeStep = SerializeStep<OperationStackInput,
                                           OperationStackOutput,
                                           OperationStackError>(id: SerializeStepId)
        self.buildStep = BuildStep<OperationStackOutput,
                                   OperationStackError>(id: BuildStepId)
        self.finalizeStep = FinalizeStep<OperationStackOutput,
                                         OperationStackError>(id: FinalizeStepId)
        self.deserializeStep = DeserializeStep<OperationStackOutput,
                                               OperationStackError>(id: DeserializeStepId)
        
    }
    
    /// This execute will execute the stack and use your next as the last closure in the chain
    public func handleMiddleware<H: Handler>(context: HttpContext,
                                             input: OperationStackInput,
                                             next: H) -> SdkResult<OperationStackOutput, OperationStackError>
    where H.Input == SdkHttpRequest,
          H.Output == OperationOutput<OperationStackOutput>,
          H.Context == HttpContext,
          H.MiddlewareError == SdkError<OperationStackError> {
        
        let deserialize = compose(next: DeserializeStepHandler(handler: next), with: deserializeStep)
        let finalize = compose(next: FinalizeStepHandler(handler: deserialize), with: finalizeStep)
        let build = compose(next: BuildStepHandler(handler: finalize), with: buildStep)
        let serialize = compose(next: SerializeStepHandler(handler: build), with: serializeStep)
        let initialize = compose(next: InitializeStepHandler(handler: serialize), with: initializeStep)
        
        let result = initialize.handle(context: context, input: input)
        return result.flatMap { operationOutput in
            return .success(operationOutput.output!)
        }
    }
    
    mutating public func presignedRequest<H: Handler>(context: HttpContext,
                                                      input: OperationStackInput,
                                                      next: H) -> SdkHttpRequestBuilder?
    where H.Input == SdkHttpRequest,
          H.Output == OperationOutput<OperationStackOutput>,
          H.Context == HttpContext,
          H.MiddlewareError == SdkError<OperationStackError> {
        var builder: SdkHttpRequestBuilder?
        self.finalizeStep.intercept(position: .after,
                                    middleware: PresignerShim(handler: { buildInMiddleware in
                                        builder = buildInMiddleware
                                    }))
        _ = handleMiddleware(context: context, input: input, next: next)
        return builder
    }

    /// Compose (wrap) the handler with the given middleware or essentially build out the linked list of middleware
    private func compose<H: Handler, M: Middleware>(next handler: H,
                                                    with middlewares: M...) -> AnyHandler<H.Input,
                                                                                          H.Output,
                                                                                          H.Context,
                                                                                          H.MiddlewareError>
    where M.MOutput == H.Output,
          M.MInput == H.Input,
          H.Context == M.Context,
          H.MiddlewareError == M.MError {
        guard !middlewares.isEmpty,
              let lastMiddleware = middlewares.last else {
            return handler.eraseToAnyHandler()
        }
        
        let numberOfMiddlewares = middlewares.count
        var composedHandler = ComposedHandler(handler, lastMiddleware)
        
        guard numberOfMiddlewares > 1 else {
            return composedHandler.eraseToAnyHandler()
        }
        let reversedCollection = (0...(numberOfMiddlewares - 2)).reversed()
        for index in reversedCollection {
            composedHandler = ComposedHandler(composedHandler, middlewares[index])
        }
        
        return composedHandler.eraseToAnyHandler()
    }
}
