// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

// used to create middleware from a middleware handler
struct WrappedMiddleware<MInput, MOutput>: Middleware {
    let _middleware: MiddlewareFunction<MInput, MOutput>
    var id: String
    
    init(_ middleware: @escaping MiddlewareFunction<MInput, MOutput>, id: String) {
        self._middleware = middleware
        self.id = id
    }
    
    func handle<H: Handler>(context: MiddlewareContext,
                            input: MInput,
                            next: H) -> Result<MOutput, Error> where H.Input == MInput,
                                                                     H.Output == MOutput {
        return _middleware(context, input, next.eraseToAnyHandler())
    }
}
