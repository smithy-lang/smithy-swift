// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct OperationStack<TSubject, TError: Error> {
    ///returns the unique id for the operation stack as middleware
    public var id: String
    public var initializeStep: InitializeStep<TSubject, TError>
    public var buildStep: BuildStep<TSubject, TError>
    public var serializeStep: SerializeStep<TSubject, TError>
    public var finalizeStep: FinalizeStep<TSubject, TError>
    public var deserializeStep: DeserializeStep<TSubject, TError>
    
    public init(id: String,
                initializeStep: InitializeStep<TSubject, TError>,
                serializeStep: SerializeStep<TSubject, TError>,
                buildStep: BuildStep<TSubject, TError>,
                finalizeStep: FinalizeStep<TSubject, TError>,
                deserializeStep: DeserializeStep<TSubject, TError>) {
        self.id = id
        self.initializeStep = initializeStep
        self.serializeStep = serializeStep
        self.buildStep = buildStep
        self.finalizeStep = finalizeStep
        self.deserializeStep = deserializeStep
    }
    
    /// This execute will execute the stack and use your next as the last closure in the chain
    func handleMiddleware<H: Handler>(context: MiddlewareContext,
                 subject: TSubject,
                 next: H) -> Result<TSubject, TError> where H.TSubject == TSubject, H.TError == TError {
        
        let steps: [AnyMiddlewareStack<TSubject, TError>] = [initializeStep.eraseToAnyMiddlewareStack(),
                                                       serializeStep.eraseToAnyMiddlewareStack(),
                                                       buildStep.eraseToAnyMiddlewareStack(),
                                                       finalizeStep.eraseToAnyMiddlewareStack(),
                                                       deserializeStep.eraseToAnyMiddlewareStack()]
        let handler = compose(handler: next, with: steps)

        let result = handler.handle(context: context, result: .success(subject))
        return result
    }
    
    /// Compose (wrap) the handler with the given middleware
    func compose<H: Handler, M: MiddlewareStack>(handler: H, with: [M]) -> AnyHandler<TSubject, TError>
        where M.TSubject == TSubject,
              M.TError == TError,
              H.TSubject == TSubject,
              H.TError == TError {
        if with.isEmpty {
            return AnyHandler(handler)
        }
        
        let cnt = with.count
        var h = ComposedHandler<TSubject, TError>(handler, with[cnt - 1])
        for i in stride(from: cnt - 2, through: 0, by: -1) {
            h = ComposedHandler(h, with[i])
        }
        
        return AnyHandler(h)
    }
}
