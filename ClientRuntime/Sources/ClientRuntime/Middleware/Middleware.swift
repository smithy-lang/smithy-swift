// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public protocol Middleware {
    associatedtype MInput
    associatedtype MOutput
    
    /// The middleware ID
    var id: String { get }
    
    func handle<H: Handler>(context: MiddlewareContext,
                            input: MInput,
                            next: H) -> Result<MOutput, Error>
    where H.Input == MInput, H.Output == MOutput
}

extension Middleware {
    func eraseToAnyMiddleware() -> AnyMiddleware<MInput, MOutput> {
        return AnyMiddleware(self)
    }
}
