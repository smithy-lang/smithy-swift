// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Type erased Handler
public struct AnyHandler<MInput, MOutput>: Handler {
    private let _handle: (MiddlewareContext, Result<MInput, Error>) -> Result<MOutput, Error>
    
    public init<H: Handler> (_ realHandler: H)
        where H.Input == MInput, H.Output == MOutput {
        if let alreadyErased = realHandler as? AnyHandler<MInput, MOutput> {
            self = alreadyErased
            return
        }
        self._handle = realHandler.handle
    }
    
    public func handle(context: MiddlewareContext, result: Result<MInput, Error>) -> Result<MOutput, Error> {
        return _handle(context, result)
    }
}
