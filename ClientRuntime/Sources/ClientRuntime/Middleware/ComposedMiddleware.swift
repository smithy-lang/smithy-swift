// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

// used to create middleware from a handler
struct ComposedMiddleware<TSubject: Any, TError: Error> {
    private var _handle: (MiddlewareContext, Result<TSubject, TError>, AnyHandler<TSubject, TError>) -> Result<TSubject, TError>
    // the next handler to call
    let handler: AnyHandler<TSubject, TError>
    public var id: String
    
    public init<H: Handler> (_ handler: H, id: String)
           where H.TSubject == TSubject, H.TError == TError {
        
        if let alreadyComposed = handler as? ComposedMiddleware<TSubject, TError> {
            self = alreadyComposed
            return
        }
        
        self.handler = AnyHandler(handler)
        self.id = id
        self._handle = {context, result, next in
            next.handle(context: context, result: result)
        }
    }
       
}

extension ComposedMiddleware: Middleware {
 
    func handle<H: Handler>(context: MiddlewareContext, result: Result<TSubject, TError>, next: H) -> Result<TSubject, TError> where
                                                                                                             H.TError == TError,
                                                                                                             H.TSubject == TSubject {
        _handle(context, result, handler)
    }
}
