// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

// handler chain, used to decorate a handler with middleware
struct ComposedHandler<TSubject: Any, TError: Error> {
    // the next handler to call
    let next: AnyHandler<TSubject, TError>
    
    // the middleware decorating 'next'
    let with: AnyMiddleware<TSubject, TError>
    
    public init<H: Handler, M: Middleware> (_ realNext: H, _ realWith: M)
           where H.TSubject == TSubject,
                 H.TError == TError,
                 M.TSubject == TSubject,
                 M.TError == TError {
        
        if let alreadyComposed = realNext as? ComposedHandler<TSubject, TError> {
            self = alreadyComposed
            return
        }
        
        self.next = AnyHandler(realNext)
        self.with = AnyMiddleware(realWith)
    }
    
}

extension ComposedHandler: Handler {
    func handle(context: MiddlewareContext, result: Result<TSubject, TError>) -> Result<TSubject, TError> {
        return self.with.handle(context: context, result: result, next: self.next)
    }
}
