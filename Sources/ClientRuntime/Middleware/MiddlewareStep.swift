//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context

/// An instance of MiddlewareStep will be contained in the operation stack, and recognized as a single
/// step (initialize, build, etc..) that contains an ordered list of middlewares. This class is
/// responsible for ordering these middlewares so that they are executed in the correct order.
public struct MiddlewareStep<Input, Output>: Middleware {
    public typealias MInput = Input
    public typealias MOutput = Output

    var orderedMiddleware: OrderedGroup<MInput,
                                        MOutput> = OrderedGroup<MInput, MOutput>()

    public let id: String

    public init(id: String) {
        self.id = id
    }

    func get(id: String) -> AnyMiddleware<MInput, MOutput>? {
        return orderedMiddleware.get(id: id)
    }

    /// This execute will execute the stack and use your next as the last closure in the chain
    public func handle<H: Handler>(context: Context,
                                   input: MInput,
                                   next: H) async throws -> MOutput
    where H.Input == MInput, H.Output == MOutput {

        var handler = next.eraseToAnyHandler()
        let order = orderedMiddleware.orderedItems

        guard !order.isEmpty else {
            return try await handler.handle(context: context, input: input)
        }
        let numberOfMiddlewares = order.count
        let reversedCollection = (0...(numberOfMiddlewares-1)).reversed()
        for index in reversedCollection {
            let composedHandler = ComposedHandler(handler, order[index].value)
            handler = composedHandler.eraseToAnyHandler()
        }

        return try await handler.handle(context: context, input: input)
    }

    public mutating func intercept<M: Middleware>(position: Position, middleware: M)
    where M.MInput == MInput, M.MOutput == MOutput {
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
                                   middleware: @escaping MiddlewareFunction<MInput, MOutput>) {
        let middleware = WrappedMiddleware(middleware, id: id)
        orderedMiddleware.add(middleware: middleware.eraseToAnyMiddleware(), position: position)
    }
}
