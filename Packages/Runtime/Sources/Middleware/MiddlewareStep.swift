// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// An instance of MiddlewareStep will be contained in the operation stack, and recognized as a single
/// step (initialize, build, etc..) that contains an ordered list of middlewares. This class is
/// responsible for ordering these middlewares so that they are executed in the correct order.
public struct MiddlewareStep<StepContext: MiddlewareContext, Input, Output, MError: Error>: Middleware {
    public typealias Context = StepContext
    public typealias MInput = Input
    public typealias MOutput = Output
    public typealias MError = MError
    
    var orderedMiddleware: OrderedGroup<MInput,
                                        MOutput,
                                        Context,
                                        MError> = OrderedGroup<MInput, MOutput, Context, MError>()
    
    public let id: String
    
    public init(id: String) {
        self.id = id
    }
    
    func get(id: String) -> AnyMiddleware<MInput, MOutput, Context, MError>? {
        return orderedMiddleware.get(id: id)
    }
    
    /// This execute will execute the stack and use your next as the last closure in the chain
    public func handle<H: Handler>(context: Context,
                                   input: MInput,
                                   next: H) -> Result<MOutput, MError>
    where H.Input == MInput, H.Output == MOutput, H.Context == Context, H.MiddlewareError == MError {
        
        var handler = next.eraseToAnyHandler()
        let order = orderedMiddleware.orderedItems
        
        guard !order.isEmpty else {
            return handler.handle(context: context, input: input)
        }
        let numberOfMiddlewares = order.count
        let reversedCollection = (0...(numberOfMiddlewares-1)).reversed()
        for index in reversedCollection {
            let composedHandler = ComposedHandler(handler, order[index].value)
            handler = composedHandler.eraseToAnyHandler()
        }
        
        let result = handler.handle(context: context, input: input)
        return result
    }
    
    public mutating func intercept<M: Middleware>(position: Position, middleware: M)
    where M.MInput == MInput, M.MOutput == MOutput, M.Context == Context, M.MError == MError {
        orderedMiddleware.add(middleware: middleware.eraseToAnyMiddleware(), position: position)
    }
    
    /// Convenience function for passing a closure directly:
    ///
    /// ```
    /// stack.intercept(position: .after, id: "Add Header") { ... }
    /// ```
    ///
    public mutating func intercept(position: Position,
                                   id: String,
                                   middleware: @escaping MiddlewareFunction<MInput, MOutput, Context, MError>) {
        let middleware = WrappedMiddleware(middleware, id: id)
        orderedMiddleware.add(middleware: middleware.eraseToAnyMiddleware(), position: position)
    }
}
