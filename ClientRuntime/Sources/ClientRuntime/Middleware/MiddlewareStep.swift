// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// this protocol sets up a stack of middlewares and handles most of the functionality be default such as
/// stringing the middlewares together into a linked list, getting a middleware and adding one to the stack.
/// The stack can then go on to act as a step in a larger stack of stacks such as `OperationStack`
public class MiddlewareStep<Input, Output>: Middleware {
    public typealias Context = HttpContext
    public typealias MInput = Input
    public typealias MOutput = Output
    /// the middleware of the stack in an ordered group
    var orderedMiddleware: OrderedGroup<MInput, MOutput, Context> = OrderedGroup<MInput, MOutput, Context>()
    /// the unique id of the stack
    public let id: String
    
    public init(id: String) {
        self.id = id
    }
    
    func get(id: String) -> AnyMiddleware<MInput, MOutput, Context>? {
        return orderedMiddleware.get(id: id)
    }
    
    /// This execute will execute the stack and use your next as the last closure in the chain
    public func handle<H: Handler>(context: Context,
                            input: MInput,
                            next: H) -> Result<MOutput, Error>
    where H.Input == MInput, H.Output == MOutput, H.Context == Context {
        
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
    
    public func intercept<M: Middleware>(position: Position, middleware: M)
    where M.MInput == MInput, M.MOutput == MOutput, M.Context == Context {
        orderedMiddleware.add(middleware: middleware.eraseToAnyMiddleware(), position: position)
    }
    
    /// Convenience function for passing a closure directly:
    ///
    /// ```
    /// stack.intercept(position: .after, id: "Add Header") { ... }
    /// ```
    ///
    public func intercept(position: Position,
                            id: String,
                            middleware: @escaping MiddlewareFunction<MInput, MOutput, Context>) {
        let middleware = WrappedMiddleware(middleware, id: id)
        orderedMiddleware.add(middleware: middleware.eraseToAnyMiddleware(), position: position)
    }
}
