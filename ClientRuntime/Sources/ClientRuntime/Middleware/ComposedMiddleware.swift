// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

// used to create middleware from a handler
struct ComposedMiddleware<MInput, MOutput> {
    // the handler to call in the middleware
    let handler: AnyHandler<MInput, MOutput>
    public var id: String
    
    public init<H: Handler> (_ handler: H, id: String)
           where H.Input == MInput, H.Output == MOutput {
        
        self.handler = handler.eraseToAnyHandler()
        self.id = id
    }
}

extension ComposedMiddleware: Middleware {
 
    func handle<H: Handler>(context: MiddlewareContext, input: MInput, next: H) -> Result<MOutput, Error> where
        H.Input == MInput, H.Output == MOutput {
        let newResult = handler.handle(context: context, input: input)

        switch newResult {
        case .failure(let error):
            return next.handle(context: context, input: error as! MInput) //this can't be right?
        case .success(let output):
            return next.handle(context: context, input: output as! MInput) //either can this?
        }
    }
}
