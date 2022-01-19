// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public protocol Middleware {
    associatedtype MInput
    associatedtype MOutput
    associatedtype Context: MiddlewareContext
    associatedtype MError: Error
    
    /// The middleware ID
    var id: String { get }
    
    func handle<H: Handler>(context: Context,
                            input: MInput,
                            next: H) -> Result<MOutput, MError>
    where H.Input == MInput, H.Output == MOutput, H.Context == Context, H.MiddlewareError == MError
}

extension Middleware {
    public func eraseToAnyMiddleware() -> AnyMiddleware<MInput, MOutput, Context, MError> {
        return AnyMiddleware(self)
    }
}
