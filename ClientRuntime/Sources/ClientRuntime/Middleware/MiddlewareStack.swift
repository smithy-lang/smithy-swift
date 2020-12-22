// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public protocol MiddlewareStack: Middleware {
    
    /// the middleware of the stack in an ordered group
    var orderedMiddleware: OrderedGroup<MInput, MOutput> { get set }
    /// the unique id of the stack
    var id: String {get set}
    
    func get(id: String) -> AnyMiddleware<MInput, MOutput>?
    
    func handle<H: Handler>(context: MiddlewareContext,
                            input: MInput,
                            next: H) -> Result<MOutput, Error>
    where H.Input == MInput, H.Output == MOutput
    
    mutating func intercept<M: Middleware>(position: Position, middleware: M)
    where M.MInput == MInput, M.MOutput == MOutput
    
    mutating func intercept(position: Position,
                            id: String,
                            handler: @escaping HandlerFunction<MInput, MOutput>)
}

public extension MiddlewareStack {
    func get(id: String) -> AnyMiddleware<MInput, MOutput>? {
        return orderedMiddleware.get(id: id)
    }
    
    /// This execute will execute the stack and use your next as the last closure in the chain
    func handle<H: Handler>(context: MiddlewareContext,
                            input: MInput,
                            next: H) -> Result<MOutput, Error>
        where H.Input == MInput, H.Output == MOutput {
        
        var handler = AnyHandler<MInput, MOutput>(next)
        let order = orderedMiddleware.orderedItems
        if order.count == 0 {
            return handler.handle(context: context, input: input)
        }
        let reversedCollection = (0...(order.count-1)).reversed()
        for index in reversedCollection {
            let composedHandler = ComposedHandler(handler, order[index].value)
            handler = composedHandler.eraseToAnyHandler()
        }
        
        let result = handler.handle(context: context, input: input)
        return result
    }
    
    mutating func intercept<M: Middleware>(position: Position, middleware: M)
    where M.MInput == MInput, M.MOutput == MOutput {
        orderedMiddleware.add(middleware: middleware.eraseToAnyMiddleware(), position: position)
    }
    
    /// Convenience function for passing a closure directly:
    ///
    /// ```
    /// stack.intercept(phase, position: .after, id: "Add Header") { ... }
    /// ```
    ///
    mutating func intercept(position: Position,
                            id: String,
                            handler: @escaping HandlerFunction<MInput, MOutput>) {
        let handlerFn = HandlerFunctionWrapper(handler)
        let anyHandler = handlerFn.eraseToAnyHandler()
        let middleware = ComposedMiddleware<MInput, MOutput>(anyHandler, id: id)
        orderedMiddleware.add(middleware: middleware.eraseToAnyMiddleware(), position: position)
    }
}

extension MiddlewareStack {
    func eraseToAnyMiddlewareStack<MInput, MOutput>() -> AnyMiddlewareStack<MInput, MOutput> where MInput == Self.MInput, MOutput == Self.MOutput {
        return AnyMiddlewareStack(self)
    }
}
