// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// type erase the Middleware Stack protocol
public struct AnyMiddlewareStack<MInput, MOutput>: MiddlewareStack {    
    public var orderedMiddleware: OrderedGroup<MInput, MOutput>
    
    private let _handle: (MiddlewareContext, MInput, AnyHandler<MInput, MOutput>) -> Result<MOutput, Error>

    public var id: String

    public init<M: MiddlewareStack>(_ realMiddleware: M)
        where M.MInput == MInput, M.MOutput == MOutput {
        if let alreadyErased = realMiddleware as? AnyMiddlewareStack<MInput, MOutput> {
            self = alreadyErased
            return
        }

        self.id = realMiddleware.id
        self._handle = realMiddleware.handle
        self.orderedMiddleware = realMiddleware.orderedMiddleware
    }

    public func handle<H: Handler>(context: MiddlewareContext, input: MInput, next: H) -> Result<MOutput, Error>
        where H.Input == MInput, H.Output == MOutput {
        return _handle(context, input, next.eraseToAnyHandler())
    }
    
}
