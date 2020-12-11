//
//  File.swift
//  
//
//  Created by Stone, Nicki on 12/11/20.
//

import Foundation
// used to create middleware from a handler
struct ComposedMiddleware<TContext: Any, TSubject: Any, TError: Error> {
    private var _handle: (TContext, TSubject, AnyHandler<TContext, TSubject, TError>) -> Result<TSubject, TError>
    // the next handler to call
    let handler: AnyHandler<TContext, TSubject, TError>
    public var id: String
    
    public init<H: Handler> (_ handler: H, id: String)
           where  H.TContext == TContext, H.TSubject == TSubject, H.TError == TError {
        
        if let alreadyComposed = handler as? ComposedMiddleware<TContext, TSubject, TError> {
            self = alreadyComposed
            return
        }
        
        self.handler = AnyHandler(handler)
        self.id = id
        self._handle = {context, subject, next in
            next.handle(context: context, subject: subject)
        }
    }
       
}

extension ComposedMiddleware : Middleware {
 
    func handle<H: Handler>(context: TContext, subject: TSubject, next: H) -> Result<TSubject, TError> where H.TContext == TContext,
                                                                                                             H.TError == TError,
                                                                                                             H.TSubject == TSubject {
        _handle(context, subject, handler)
    }
}
