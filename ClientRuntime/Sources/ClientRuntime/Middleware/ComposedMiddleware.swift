// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

// used to create middleware from a handler
struct ComposedMiddleware<MInput: Any, MOutput> {
    private var _handle: (MiddlewareContext, Result<MInput, Error>, AnyHandler<MInput, MOutput>) -> Result<MOutput, Error>
    // the next handler to call
    let handler: AnyHandler<MInput, MOutput>
    public var id: String
    
    public init<H: Handler> (_ handler: H, id: String)
           where H.Input == MInput, H.Output == MOutput {
        
        if let alreadyComposed = handler as? ComposedMiddleware<MInput, MOutput> {
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
 
    func handle<H: Handler>(context: MiddlewareContext, result: Result<MInput, Error>, next: H) -> Result<MOutput, Error> where
        H.Input == MInput, H.Output == MOutput {
        _handle(context, result, handler)
    }
}
