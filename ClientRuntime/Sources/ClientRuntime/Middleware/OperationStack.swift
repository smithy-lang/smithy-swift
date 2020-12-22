// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct OperationStack {
    ///returns the unique id for the operation stack as middleware
    public var id: String
    public var initializeStep: InitializeStep<Any, Any>
    public var buildStep: BuildStep<Any, Any>
    public var serializeStep: SerializeStep<Any, Any>
    public var finalizeStep: FinalizeStep<Any, Any>
    public var deserializeStep: DeserializeStep<Any, Any>
    
    public init(id: String,
                initializeStep: InitializeStep<Any, Any>,
                serializeStep: SerializeStep<Any, Any>,
                buildStep: BuildStep<Any, Any>,
                finalizeStep: FinalizeStep<Any, Any>,
                deserializeStep: DeserializeStep<Any, Any>) {
        self.id = id
        self.initializeStep = initializeStep
        self.serializeStep = serializeStep
        self.buildStep = buildStep
        self.finalizeStep = finalizeStep
        self.deserializeStep = deserializeStep
    }
    
    /// This execute will execute the stack and use your next as the last closure in the chain
    func handleMiddleware<H: Handler>(context: MiddlewareContext,
                                      subject: Any,
                                      next: H) -> Result<Any, Error> where H.Input == Any, H.Output == Any {
        
        let steps: [AnyMiddlewareStack<Any, Any>] = [initializeStep.eraseToAnyMiddlewareStack(),
                                                       serializeStep.eraseToAnyMiddlewareStack(),
                                                       buildStep.eraseToAnyMiddlewareStack(),
                                                       finalizeStep.eraseToAnyMiddlewareStack(),
                                                       deserializeStep.eraseToAnyMiddlewareStack()]
        let handler = compose(next: next, with: steps)

        let result = handler.handle(context: context, input: subject)
        return result
    }
    
    /// Compose (wrap) the handler with the given middleware
    func compose<H: Handler, M: MiddlewareStack>(next: H, with: [M]) -> AnyHandler<M.MInput, M.MOutput> where M.MInput == Any,
                                                                                                                  M.MOutput == Any,
    H.Input == Any, H.Output == Any{
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
