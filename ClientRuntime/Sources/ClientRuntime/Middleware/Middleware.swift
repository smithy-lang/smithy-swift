// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public protocol Middleware {
    associatedtype TSubject
    associatedtype TError: Error
    
    /// The middleware ID
    var id: String { get }
    
    func handle<H: Handler>(context: MiddlewareContext,
                            result: Result<TSubject, TError>,
                            next: H) -> Result<TSubject, TError>
        where H.TSubject == TSubject, H.TError == TError
}

extension Middleware {
    func eraseToAnyMiddleware() -> AnyMiddleware<TSubject, TError> {
        return AnyMiddleware(self)
    }
}
