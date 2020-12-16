// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 // SPDX-License-Identifier: Apache-2.0.

/// type erase the Middleware protocol
public struct AnyMiddleware<TContext, TSubject, TError: Error>: Middleware {
    private let _handle: (TContext, Result<TSubject, TError>, AnyHandler<TContext, TSubject, TError>) -> Result<TSubject, TError>

    public var id: String

    public init<M: Middleware>(_ realMiddleware: M)
        where M.TContext == TContext, M.TSubject == TSubject, M.TError == TError {
        if let alreadyErased = realMiddleware as? AnyMiddleware<TContext, TSubject, TError> {
            self = alreadyErased
            return
        }

        self.id = realMiddleware.id
        self._handle = realMiddleware.handle
    }
    
    public init<H: Handler>(handler: H, id: String) where H.TContext == TContext, H.TSubject == TSubject, H.TError == TError {
        
        self._handle = { context, result, handler in
            handler.handle(context: context, result: result)
        }
        self.id = id
    }

    public func handle<H>(context: TContext, result: Result<TSubject, TError>, next: H) -> Result<TSubject, TError>
        where H: Handler, H.TContext == TContext, H.TSubject == TSubject, H.TError == TError {
        return _handle(context, result, AnyHandler(next))
    }
    
}
