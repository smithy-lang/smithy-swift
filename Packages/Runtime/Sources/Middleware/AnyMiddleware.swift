// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// type erase the Middleware protocol
public struct AnyMiddleware<MInput, MOutput, Context: MiddlewareContext, MError: Error>: Middleware {
    
    private let _handle: (Context, MInput, AnyHandler<MInput, MOutput, Context, MError>) -> Result<MOutput, MError>

    public var id: String

    public init<M: Middleware>(_ realMiddleware: M)
    where M.MInput == MInput, M.MOutput == MOutput, M.Context == Context, M.MError == MError {
        if let alreadyErased = realMiddleware as? AnyMiddleware<MInput, MOutput, Context, MError> {
            self = alreadyErased
            return
        }

        self.id = realMiddleware.id
        self._handle = realMiddleware.handle
    }
    
    public init<H: Handler>(handler: H, id: String) where H.Input == MInput,
                                                          H.Output == MOutput,
                                                          H.Context == Context,
                                                          H.MiddlewareError == MError {
        
        self._handle = { context, input, handler in
            handler.handle(context: context, input: input)
        }
        self.id = id
    }

    public func handle<H: Handler>(context: Context, input: MInput, next: H) -> Result<MOutput, MError>
    where H.Input == MInput,
          H.Output == MOutput,
          H.Context == Context,
          H.MiddlewareError == MError {
        return _handle(context, input, next.eraseToAnyHandler())
    }
}
