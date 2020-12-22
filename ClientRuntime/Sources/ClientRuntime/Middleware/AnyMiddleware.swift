// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// type erase the Middleware protocol
public struct AnyMiddleware<MInput, MOutput>: Middleware {
    
    private let _handle: (MiddlewareContext, MInput, AnyHandler<MInput, MOutput>) -> Result<MOutput, Error>

    public var id: String

    public init<M: Middleware>(_ realMiddleware: M)
        where M.MInput == MInput, M.MOutput == MOutput {
        if let alreadyErased = realMiddleware as? AnyMiddleware<MInput, MOutput> {
            self = alreadyErased
            return
        }

        self.id = realMiddleware.id
        self._handle = realMiddleware.handle
    }
    
    public init<H: Handler>(handler: H, id: String) where H.Input == MInput, H.Output == MOutput {
        
        self._handle = { context, input, handler in
            handler.handle(context: context, input: input)
        }
        self.id = id
    }

    public func handle<H: Handler>(context: MiddlewareContext, input: MInput, next: H) -> Result<MOutput, Error>
        where H.Input == MInput, H.Output == MOutput {
        return _handle(context, input, next.eraseToAnyHandler())
    }
    
}
