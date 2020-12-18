// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Type erased Handler
public struct AnyHandler<TSubject, TError: Error>: Handler {
    private let _handle: (MiddlewareContext, Result<TSubject, TError>) -> Result<TSubject, TError>
    
    public init<H: Handler> (_ realHandler: H)
        where H.TSubject == TSubject, H.TError == TError {
        if let alreadyErased = realHandler as? AnyHandler<TSubject, TError> {
            self = alreadyErased
            return
        }
        self._handle = realHandler.handle
    }
    
    public func handle(context: MiddlewareContext, result: Result<TSubject, TError>) -> Result<TSubject, TError> {
        return _handle(context, result)
    }
}
