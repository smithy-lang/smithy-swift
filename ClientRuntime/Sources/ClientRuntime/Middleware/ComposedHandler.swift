// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

// handler chain, used to decorate a handler with middleware
struct ComposedHandler<MInput: Any, MOutput> {
    // the next handler to call
    let next: AnyHandler<MInput, MOutput>
    
    // the middleware decorating 'next'
    let with: AnyMiddleware<MInput, MOutput>
    
    public init<H: Handler, M: Middleware> (_ realNext: H, _ realWith: M)
           where H.Input == MInput,
                 H.Output == MOutput,
                 M.MInput == MInput,
                 M.MOutput == MOutput {
        
        if let alreadyComposed = realNext as? ComposedHandler<MInput, MOutput> {
            self = alreadyComposed
            return
        }
        
        self.next = AnyHandler(realNext)
        self.with = AnyMiddleware(realWith)
    }
    
}

extension ComposedHandler: Handler {
    func handle(context: MiddlewareContext, result: Result<MInput, Error>) -> Result<MOutput, Error> {
        return self.with.handle(context: context, result: result, next: self.next)
    }
}
