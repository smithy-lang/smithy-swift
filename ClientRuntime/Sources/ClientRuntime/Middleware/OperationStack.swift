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
        self.initializeStep = InitializeStep<OperationStackInput, OperationStackOutput, OperationStackError>(id: "Initialize")
        self.serializeStep = SerializeStep<OperationStackInput, OperationStackOutput, OperationStackError>(id: "Serialize")
        self.buildStep = BuildStep<OperationStackOutput, OperationStackError>(id: "Build")
        self.finalizeStep = FinalizeStep<OperationStackOutput, OperationStackError>(id: "Finalize")
        self.deserializeStep = DeserializeStep<OperationStackOutput, OperationStackError>(id: "Deserialize")
        
    }
    
    /// This function if called adds all default middlewares to a typical sdk operation,
    ///  can optionally call from the service client inside an operation
    public mutating func addDefaultOperationMiddlewares() {
        buildStep.intercept(position: .before, middleware: ContentLengthMiddleware<OperationStackOutput, OperationStackError>())
        deserializeStep.intercept(position: .before, middleware: DeserializeMiddleware<OperationStackOutput, OperationStackError>())
    }
    
    /// This execute will execute the stack and use your next as the last closure in the chain
    public func handleMiddleware<H: Handler>(context: HttpContext,
                                             input: OperationStackInput,
                                             next: H) -> SdkResult<OperationStackOutput, OperationStackError>
    where H.Input == SdkHttpRequest, H.Output == OperationOutput<OperationStackOutput, OperationStackError>, H.Context == HttpContext {

        let deserialize = compose(next: DeserializeStepHandler(inner: next), with: deserializeStep)
        let finalize = compose(next: FinalizeStepHandler(inner: deserialize), with: finalizeStep)
        let build = compose(next: BuildStepHandler(inner: finalize), with: buildStep)
        let serialize = compose(next: SerializeStepHandler(inner: build), with: serializeStep)
        let initialize = compose(next: InitializeStepHandler(inner: serialize), with: initializeStep)
        
        let result = initialize.handle(context: context, input: input)

        switch result {
        case .failure(let error):
            return .failure(.unknown(error))
        case .success(let output):
            if let stackError = output.error {
                return .failure(.service(stackError))
            } else {
                return .success(output.output!) // output should not be nil here ever if error is nil
            }
        }
    }
    
    /// Compose (wrap) the handler with the given middleware or essentially build out the linked list of middleware
    public func compose<H: Handler, M: Middleware>(next handler: H,
                                                   with middlewares: M...) -> AnyHandler<H.Input,
                                                                                 H.Output,
                                                                                 H.Context> where M.MOutput == H.Output,
                                                                                                  M.MInput == H.Input,
                                                                                                  H.Context == M.Context {
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
