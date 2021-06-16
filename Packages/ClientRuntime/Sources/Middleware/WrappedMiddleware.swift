// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// used to create middleware from a middleware function
struct WrappedMiddleware<MInput, MOutput, Context: MiddlewareContext, MError: Error>: Middleware {
    let _middleware: MiddlewareFunction<MInput, MOutput, Context, MError>
    var id: String
    
    init(_ middleware: @escaping MiddlewareFunction<MInput, MOutput, Context, MError>, id: String) {
        self._middleware = middleware
        self.id = id
    }
    
    func handle<H: Handler>(context: Context,
                            input: MInput,
                            next: H) -> Result<MOutput, MError> where H.Input == MInput,
                                                                     H.Output == MOutput,
                                                                     H.Context == Context,
                                                                     H.MiddlewareError == MError {
        return _middleware(context, input, next.eraseToAnyHandler())
    }
}
