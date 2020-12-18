// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// type erase the Middleware Stack protocol
public struct AnyMiddlewareStack<TSubject, TError: Error>: MiddlewareStack {
    public var orderedMiddleware: OrderedGroup<TSubject, TError>
    
    private let _handle: (MiddlewareContext, Result<TSubject, TError>, AnyHandler<TSubject, TError>) -> Result<TSubject, TError>

    public var id: String

    public init<M: MiddlewareStack>(_ realMiddleware: M)
        where M.TSubject == TSubject, M.TError == TError {
        if let alreadyErased = realMiddleware as? AnyMiddlewareStack<TSubject, TError> {
            self = alreadyErased
            return
        }

        self.id = realMiddleware.id
        self._handle = realMiddleware.handle
        self.orderedMiddleware = realMiddleware.orderedMiddleware
    }

    public func handle<H: Handler>(context: MiddlewareContext, result: Result<TSubject, TError>, next: H) -> Result<TSubject, TError>
        where H.TSubject == TSubject, H.TError == TError {
        return _handle(context, result, AnyHandler(next))
    }
    
}
