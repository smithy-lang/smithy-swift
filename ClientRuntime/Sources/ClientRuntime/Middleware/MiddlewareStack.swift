// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public protocol MiddlewareStack: Middleware {
    
    /// the middleware of the stack in an ordered group
    var orderedMiddleware: OrderedGroup<TSubject, TError> { get set }
    /// the unique id of the stack
    var id: String {get set}
    
    func get(id: String) -> AnyMiddleware<TSubject, TError>?
    
    func handle<H: Handler>(context: MiddlewareContext,
                            result: Result<TSubject, TError>,
                            next: H) -> Result<TSubject, TError>
        where H.TSubject == TSubject, H.TError == TError
    
    mutating func intercept<M: Middleware>(position: Position, middleware: M)
    where M.TSubject == TSubject, M.TError == TError
    
    mutating func intercept(position: Position,
                            id: String,
                            handler: @escaping HandlerFunction<TSubject, TError>)
}

public extension MiddlewareStack {
    func get(id: String) -> AnyMiddleware<TSubject, TError>? {
        return orderedMiddleware.get(id: id)
    }
    
    /// This execute will execute the stack and use your next as the last closure in the chain
    public func handle<H: Handler>(context: MiddlewareContext,
                            result: Result<TSubject, TError>,
                            next: H) -> Result<TSubject, TError>
        where H.TSubject == TSubject, H.TError == TError {
        
        var handler = AnyHandler<TSubject, TError>(next)
        
        let order = orderedMiddleware.orderedItems
        let reversedCollection = (0...(order.count-1)).reversed()
        for index in reversedCollection {
            let composedHandler = ComposedHandler(handler, order[index].value)
            handler = AnyHandler(composedHandler)
        }
        
        let result = handler.handle(context: context, result: result)
        return result
    }
    
    mutating func intercept<M: Middleware>(position: Position, middleware: M)
    where M.TSubject == TSubject, M.TError == TError {
        orderedMiddleware.add(middleware: AnyMiddleware(middleware), position: position)
    }
    
    /// Convenience function for passing a closure directly:
    ///
    /// ```
    /// stack.intercept(phase, position: .after, id: "Add Header") { ... }
    /// ```
    ///
    mutating func intercept(position: Position,
                            id: String,
                            handler: @escaping HandlerFunction<TSubject, TError>) {
        let handlerFn = HandlerFunctionWrapper(handler)
        let anyHandler = AnyHandler<TSubject, TError>(handlerFn)
        let middleware = ComposedMiddleware<TSubject, TError>(anyHandler, id: id)
        orderedMiddleware.add(middleware: AnyMiddleware(middleware), position: position)
    }
}

extension MiddlewareStack {
    func eraseToAnyMiddlewareStack<TSubject, TError>() -> AnyMiddlewareStack<TSubject, TError> where TSubject == Self.TSubject, TError == Self.TError {
        return AnyMiddlewareStack(self)
    }
}
