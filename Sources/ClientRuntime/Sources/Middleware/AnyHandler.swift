// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Type erased Handler
public struct AnyHandler<MInput, MOutput, Context: MiddlewareContext, MError: Error>: Handler {
    private let _handle: (Context, MInput) -> Result<MOutput, MError>
    
    public init<H: Handler> (_ realHandler: H)
    where H.Input == MInput, H.Output == MOutput, H.Context == Context, H.MiddlewareError == MError {
        if let alreadyErased = realHandler as? AnyHandler<MInput, MOutput, Context, MError> {
            self = alreadyErased
            return
        }
        self._handle = realHandler.handle
    }
    
    public func handle(context: Context, input: MInput) -> Result<MOutput, MError> {
        return _handle(context, input)
    }
}
