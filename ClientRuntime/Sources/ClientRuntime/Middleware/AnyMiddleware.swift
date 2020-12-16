// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// type erase the Middleware protocol
public struct AnyMiddleware<MInput, MOutput, Context: MiddlewareContext>: Middleware {    
    
    private let _handle: (Context, MInput, AnyHandler<MInput, MOutput, Context>) -> Result<MOutput, Error>

    public var id: String

    public init<M: Middleware>(_ realMiddleware: M)

    where M.MInput == MInput, M.MOutput == MOutput, M.Context == Context {
        if let alreadyErased = realMiddleware as? AnyMiddleware<MInput, MOutput, Context> {
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
    
    public init<H: Handler>(handler: H, id: String) where H.Input == MInput, H.Output == MOutput, H.Context == Context {
        
        self._handle = { context, input, handler in
            handler.handle(context: context, input: input)
        }
        self.id = id
    }

<<<<<<< HEAD
    public func handle<H: Handler>(context: Context, input: MInput, next: H) -> Result<MOutput, Error>
    where H.Input == MInput, H.Output == MOutput, H.Context == Context {
        return _handle(context, input, next.eraseToAnyHandler())
=======
    public func handle<H>(context: TContext, result: Result<TSubject, TError>, next: H) -> Result<TSubject, TError>
        where H: Handler, H.TContext == TContext, H.TSubject == TSubject, H.TError == TError {
        return _handle(context, result, AnyHandler(next))
>>>>>>> 8425baf... fix: linter errors
    }
}
